'use client';

import { Address, Avatar, EthBalance, Identity, Name } from "@coinbase/onchainkit/identity";
import { ConnectWallet, Wallet, WalletDropdown, WalletDropdownDisconnect, WalletDropdownLink } from "@coinbase/onchainkit/wallet";
import { useAccount } from "wagmi";
import { useState, useEffect } from 'react';

export default function Layout({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  const account = useAccount();

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen font-sans dark:bg-background dark:text-white bg-white text-black">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold mb-4">NFL Playoff Bracket 2025</h1>
          <p className="text-gray-600">Make your predictions for the playoff games!</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen font-sans dark:bg-background dark:text-white bg-white text-black">
      {account?.address && (
        <div className='absolute top-4 right-4'>
          <Wallet>
            <ConnectWallet>
              <Avatar className="h-6 w-6" />
              <Name />
            </ConnectWallet>
            <WalletDropdown>
              <Identity className="px-4 pt-3 pb-2" hasCopyAddressOnClick>
                <Avatar />
                <Name />
                <Address />
                <EthBalance />
              </Identity>
              <WalletDropdownLink
                icon="wallet"
                href="https://keys.coinbase.com"
                target="_blank"
                rel="noopener noreferrer"
              >
                Wallet
              </WalletDropdownLink>
              <WalletDropdownDisconnect />
            </WalletDropdown>
          </Wallet>
        </div>
      )}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold mb-4">NFL Playoff Bracket 2025</h1>
        <p className="text-gray-600">Make your predictions for the playoff games!</p>
      </div>
      {children}
    </div>
  );
} 