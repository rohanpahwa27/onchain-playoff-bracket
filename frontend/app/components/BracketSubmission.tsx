'use client';

import { useAccount, useReadContract, useChainId, useSwitchChain } from 'wagmi';
import { onchainPlayoffBracketContract, OnchainPlayoffBracketAbi, DEFAULT_GROUP_NAME } from '../lib/OnchainPlayoffBracket';
import { parseEther, encodeFunctionData } from 'viem';
import { ConnectWallet } from '@coinbase/onchainkit/wallet';
import { Transaction, TransactionButton, TransactionStatus, TransactionStatusLabel, TransactionStatusAction } from '@coinbase/onchainkit/transaction';
import { baseSepolia } from 'viem/chains';

interface BracketSubmissionProps {
  selections: string[];
  formatBracketSelections: () => string[];
}

export default function BracketSubmission({ 
  selections, 
  formatBracketSelections 
}: BracketSubmissionProps) {
  const { address } = useAccount();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  const { data: bracketCreationStatus } = useReadContract({
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'canCreateNewBracket'
  });

  const { data: hasSubmitted } = useReadContract({
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'hasSubmittedGroupBracket',
    args: address ? [address as `0x${string}`, DEFAULT_GROUP_NAME] : undefined
  });

  // Auto-switch to Base Sepolia if on wrong chain
  if (chainId && chainId !== baseSepolia.id) {
    switchChain({ chainId: baseSepolia.id });
  }

  const calls = [{
    to: onchainPlayoffBracketContract as `0x${string}`,
    data: encodeFunctionData({
      abi: OnchainPlayoffBracketAbi,
      functionName: "createBracket",
      args: [formatBracketSelections(), DEFAULT_GROUP_NAME, "public", parseEther("0.000001")],
    }),
    value: parseEther("0.000001")
  }];

  const allSelectionsMade = selections.every(selection => selection !== '');

  if (!address) {
    return (
      <ConnectWallet 
        className="mt-16 px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
      >
        Connect Wallet
      </ConnectWallet>
    );
  }

  if (!bracketCreationStatus) {
    return (
      <button 
        className="mt-16 px-6 py-3 bg-gray-500 text-white rounded-lg cursor-not-allowed"
        disabled
      >
        Bracket Creation Paused
      </button>
    );
  }

  if (hasSubmitted) {
    return (
      <button 
        className="mt-16 px-6 py-3 bg-gray-500 text-white rounded-lg cursor-not-allowed"
        disabled
      >
        Bracket Already Submitted
      </button>
    );
  }

  return (
    <Transaction
      isSponsored={false}
      chainId={baseSepolia.id}
      calls={calls}
      onStatus={(status) => {
        console.log('Transaction status:', status);
        console.log('Current selections:', selections);
        console.log('Selection length:', selections.length);
        console.log('Empty selections:', selections.filter(s => s === '').length);
      }}
      onError={(error) => {
        console.error('Transaction error:', error);
        console.error('Current selections:', selections);
      }}
      onSuccess={(receipt) => {
        console.log('Transaction success:', receipt);
      }}
    >
      <TransactionButton 
        className="mt-16 px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:opacity-50 disabled:hover:bg-green-500"
        disabled={!allSelectionsMade}
        text="Submit Bracket (0.000001 ETH)"
      />
      <TransactionStatus>
        <TransactionStatusLabel />
        <TransactionStatusAction />
      </TransactionStatus>
    </Transaction>
  );
}
