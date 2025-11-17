// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdFunding {
    struct Campaign {
        uint256 id;              // เก็บ id ไว้ใน struct
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        bool withdrawn;
    }

    // ใช้ mapping แทน array
    mapping(uint256 => Campaign) private campaigns;

    // เก็บรายการ id ของแคมเปญที่ยัง active เพื่อเอาไว้วนใน getCampaigns()
    uint256[] private campaignIds;
    // id -> index ใน campaignIds (เอาไว้ลบแบบ O(1))
    mapping(uint256 => uint256) private campaignIndex;

    uint256 public nextCampaignId;

    event CampaignCreated(
        uint256 indexed id,
        address indexed owner,
        string title,
        uint256 target,
        uint256 deadline
    );

    event DonationReceived(
        uint256 indexed id,
        address indexed donor,
        uint256 amount
    );

    event FundsWithdrawn(
        uint256 indexed id,
        address indexed owner,
        uint256 amount
    );

    event CampaignDeleted(uint256 indexed id);

    // ---------- CREATE ----------

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) external returns (uint256) {
        require(_owner != address(0), "Invalid owner");
        require(_target > 0, "Target must be > 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 id = nextCampaignId++;

        Campaign storage campaign = campaigns[id];
        campaign.id = id;
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        campaignIds.push(id);
        campaignIndex[id] = campaignIds.length - 1;

        emit CampaignCreated(id, _owner, _title, _target, _deadline);
        return id;
    }

    // ---------- READ ----------

    function getCampaigns() external view returns (Campaign[] memory) {
        uint256 length = campaignIds.length;
        Campaign[] memory result = new Campaign[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = campaigns[campaignIds[i]];
        }

        return result;
    }

    function getDonators(
        uint256 _id
    ) external view returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist");
        return (campaign.donators, campaign.donations);
    }

    function numberOfCampaigns() external view returns (uint256) {
        return campaignIds.length;
    }

    // ---------- DONATE ----------

    function donateToCampaign(uint256 _id) external payable {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be > 0");
        require(!campaign.withdrawn, "Funds already withdrawn");

        campaign.amountCollected += msg.value;
        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        emit DonationReceived(_id, msg.sender, msg.value);
    }

    // ---------- WITHDRAW ----------

    function withdrawFunds(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist");
        require(msg.sender == campaign.owner, "Only owner can withdraw");
        require(!campaign.withdrawn, "Already withdrawn");
        require(
            campaign.amountCollected >= campaign.target,
            "Target not reached"
        );

        campaign.withdrawn = true;
        uint256 amount = campaign.amountCollected;
        campaign.amountCollected = 0;

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit FundsWithdrawn(_id, campaign.owner, amount);
    }

    // ---------- DELETE (ตามที่คุณต้องการ) ----------

    function deleteCampaign(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist");

        // ต้องเป็นเจ้าของเท่านั้น
        require(msg.sender == campaign.owner, "Only owner can delete");

        // เพื่อความปลอดภัย: ห้ามลบถ้ามีเงินเข้าแล้วหรือถอนเงินแล้ว
        require(!campaign.withdrawn, "Cannot delete after withdraw");
        require(
            campaign.amountCollected == 0,
            "Cannot delete after donations"
        );

        // ลบจาก array campaignIds แบบ O(1) (swap กับตัวสุดท้าย แล้ว pop)
        uint256 idx = campaignIndex[_id];
        uint256 lastId = campaignIds[campaignIds.length - 1];

        if (idx != campaignIds.length - 1) {
            campaignIds[idx] = lastId;
            campaignIndex[lastId] = idx;
        }

        campaignIds.pop();
        delete campaignIndex[_id];

        // ลบตัว campaign เอง
        delete campaigns[_id];

        emit CampaignDeleted(_id);
    }
}
