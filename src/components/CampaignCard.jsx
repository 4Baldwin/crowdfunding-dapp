import React from 'react';
import { format } from 'date-fns';
import { CampaignProgress } from './CampaignProgress';
import { DonationForm } from './DonationForm';
import { CampaignOwner } from './CampaignOwner';
import { DonorsList } from './DonorsList';
import { WithdrawButton } from './WithdrawButton';
import { useWeb3 } from '../context/Web3Context';

export function CampaignCard({ campaign }) {
  const { address, deleteCampaign } = useWeb3();

  const isOwner =
    address && campaign.owner
      ? address.toLowerCase() === campaign.owner.toLowerCase()
      : false;

  const canDelete =
    isOwner &&
    Number(campaign.amountCollected) === 0 &&
    !campaign.withdrawn;

  const handleDelete = async () => {
    const ok = window.confirm('Are you sure you want to delete this campaign?');
    if (!ok) return;

    try {
      await deleteCampaign(campaign.id);
    } catch (err) {
      console.error('Error deleting campaign:', err);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden flex flex-col hover:shadow-2xl transition-all duration-300 hover:scale-105">
      <img
        src={campaign.image}
        alt={campaign.title}
        className="w-full h-48 object-cover"
      />
      <div className="p-4 flex-1">
        <h3 className="text-xl font-bold mb-2">{campaign.title}</h3>

        <p className="text-gray-600 font-medium mb-4">{campaign.description}</p>

        <CampaignProgress
          amountCollected={campaign.amountCollected}
          target={campaign.target}
        />

        <div className="flex justify-between text-sm mt-3">
          <div>
            <span className="text-gray-500">Ends on</span>
            <p className="font-medium">
              {format(campaign.deadline, 'PPP')}
            </p>
          </div>
          <div className="text-right">
            <CampaignOwner owner={campaign.owner} />
          </div>
        </div>

        <DonorsList
          donators={campaign.donators}
          donations={campaign.donations}
        />
      </div>

      <div className="px-4 pb-4 space-y-2">
        {isOwner ? (
          <WithdrawButton campaignId={campaign.id} campaign={campaign} />
        ) : (
          <DonationForm campaignId={campaign.id} campaign={campaign} />
        )}

        {canDelete && (
          <button
            onClick={handleDelete}
            className="w-full bg-red-600 text-white py-2 rounded-md hover:bg-red-700 transition-colors"
          >
            Delete Campaign
          </button>
        )}
      </div>
    </div>
  );
}
