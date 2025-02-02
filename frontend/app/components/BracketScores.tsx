'use client';

import { useContractRead } from 'wagmi';
import { onchainPlayoffBracketContract, OnchainPlayoffBracketAbi } from '../lib/OnchainPlayoffBracket';
import { useState, useEffect } from 'react';

export default function BracketScores() {
  const [mounted, setMounted] = useState(false);

  const { data: scoresData } = useContractRead({
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'getAllScores',
    watch: true,
  });

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  const addresses = scoresData?.[0] || [];
  const scores = scoresData?.[1] || [];

  // Combine addresses and scores into objects for sorting
  const bracketScores = addresses.map((address, index) => ({
    address: address as string,
    score: Number(scores[index] || 0),
  }));

  // Sort by score in descending order
  bracketScores.sort((a, b) => b.score - a.score);

  return (
    <div className="w-full max-w-2xl mx-auto mt-8 p-4">
      <h2 className="text-2xl font-bold mb-4 text-center">Bracket Scores</h2>
      {bracketScores.length === 0 ? (
        <p className="text-center text-gray-500">No brackets submitted yet</p>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Rank
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Address
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Score
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {bracketScores.map((bracket, index) => (
                <tr key={bracket.address}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    #{index + 1}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-mono">
                    {bracket.address.slice(0, 6)}...{bracket.address.slice(-4)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {bracket.score}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
} 