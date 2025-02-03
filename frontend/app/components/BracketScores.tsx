'use client';

import { useReadContract } from 'wagmi';
import { onchainPlayoffBracketContract, OnchainPlayoffBracketAbi } from '../lib/OnchainPlayoffBracket';
import { useState, useEffect } from 'react';

interface BracketScore {
  address: string;
  score: number;
  picks?: string[][];
}

export default function BracketScores() {
  const [mounted, setMounted] = useState(false);
  const [addresses, setAddresses] = useState<`0x${string}`[]>([]);
  const [bracketScores, setBracketScores] = useState<BracketScore[]>([]);

  const { data: scoresData } = useReadContract({
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'getAllScores'
  });

  // Get predictions for each address
  const { data: picksData } = useReadContract({
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'getBracketPredictions',
    args: addresses.length > 0 ? [addresses[0]] : undefined
  });

  useEffect(() => {
    setMounted(true);
    if (Array.isArray(scoresData) && scoresData[0]) {
      setAddresses(scoresData[0] as `0x${string}`[]);
    }
  }, [scoresData]);

  useEffect(() => {
    if (Array.isArray(scoresData) && scoresData[0] && scoresData[1]) {
      const addresses = scoresData[0] as string[];
      const scores = scoresData[1].map(score => Number(score));
      
      const newBracketScores: BracketScore[] = addresses.map((address, index) => ({
        address: address.toLowerCase(),
        score: scores[index] || 0,
        picks: undefined
      }));

      // Sort by score in descending order
      newBracketScores.sort((a, b) => b.score - a.score);
      setBracketScores(newBracketScores);
    }
  }, [scoresData]);

  useEffect(() => {
    if (picksData && bracketScores.length > 0) {
      const updatedScores = bracketScores.map(score => {
        if (score.address === addresses[0]?.toLowerCase()) {
          return {
            ...score,
            picks: picksData as string[][]
          };
        }
        return score;
      });
      setBracketScores(updatedScores);
    }
  }, [picksData, addresses]);

  if (!mounted) return null;

  return (
    <div className="mt-16 w-full max-w-6xl">
      <h2 className="text-2xl font-bold mb-4">Bracket Scores</h2>
      {bracketScores.length > 0 ? (
        <div className="bg-white shadow rounded-lg overflow-x-auto">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rank</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Score</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Wild Card</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Divisional</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Conference</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Super Bowl</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {bracketScores.map((score, index) => (
                <tr key={score.address}>
                  <td className="px-4 py-4 whitespace-nowrap text-sm text-gray-500">{index + 1}</td>
                  <td className="px-4 py-4 whitespace-nowrap text-sm font-mono text-gray-900 group relative">
                    <span className="cursor-help">
                      {score.address.slice(0, 6)}...{score.address.slice(-4)}
                      <span className="invisible group-hover:visible absolute z-10 bg-black text-white p-2 rounded text-xs -mt-8 left-0">
                        {score.address}
                      </span>
                    </span>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap text-sm text-gray-900">{score.score}</td>
                  <td className="px-4 py-4 text-sm text-gray-900 max-w-xs">
                    <div className="flex flex-wrap gap-1">
                      {score.picks?.[0]?.map((pick, i) => (
                        <span key={i} className="bg-gray-100 px-2 py-1 rounded">{pick}</span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-900 max-w-xs">
                    <div className="flex flex-wrap gap-1">
                      {score.picks?.[1]?.map((pick, i) => (
                        <span key={i} className="bg-gray-100 px-2 py-1 rounded">{pick}</span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-900 max-w-xs">
                    <div className="flex flex-wrap gap-1">
                      {score.picks?.[2]?.map((pick, i) => (
                        <span key={i} className="bg-gray-100 px-2 py-1 rounded">{pick}</span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-900">
                    <div className="flex flex-wrap gap-1">
                      {score.picks?.[3]?.map((pick, i) => (
                        <span key={i} className="bg-gray-100 px-2 py-1 rounded">{pick}</span>
                      ))}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="text-gray-500">No brackets submitted yet.</p>
      )}
    </div>
  );
} 