'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { onchainPlayoffBracketContract, OnchainPlayoffBracketAbi } from '../lib/OnchainPlayoffBracket';
import { parseEther } from 'viem';
import { ConnectWallet } from '@coinbase/onchainkit/wallet';
import { Transaction, TransactionButton, TransactionStatus, TransactionStatusLabel, TransactionStatusAction } from '@coinbase/onchainkit/transaction';
import { baseSepolia } from 'viem/chains';

interface Game {
  id: number;
  round: number;
  team1: string;
  team2: string;
}

const INITIAL_GAMES: Game[] = [
  // Round 1 (6 games) - AFC Side (3 games)
  { id: 1, round: 1, team1: 'Bills', team2: 'Broncos' },
  { id: 2, round: 1, team1: 'Ravens', team2: 'Steelers' },
  { id: 3, round: 1, team1: 'Texans', team2: 'Chargers' },
  // Round 1 - NFC Side (3 games)
  { id: 4, round: 1, team1: 'Eagles', team2: 'Packers' },
  { id: 5, round: 1, team1: 'Buccaneers', team2: 'Commanders' },
  { id: 6, round: 1, team1: 'Rams', team2: 'Vikings' },
  // Round 2 (4 slots) - AFC Divisional
  { id: 7, round: 2, team1: 'Chiefs', team2: '' },  // Chiefs have bye, will play lowest remaining seed
  { id: 8, round: 2, team1: '', team2: '' },        // Other AFC divisional game
  // Round 2 - NFC Divisional
  { id: 9, round: 2, team1: 'Lions', team2: '' },   // Lions have bye, will play lowest remaining seed
  { id: 10, round: 2, team1: '', team2: '' },       // Other NFC divisional game
  // Round 3 (2 slots) - Conference Championships
  { id: 11, round: 3, team1: '', team2: '' },  // AFC Championship
  { id: 12, round: 3, team1: '', team2: '' },  // NFC Championship
  // Round 4 (1 slot - Super Bowl)
  { id: 13, round: 4, team1: '', team2: '' },
];

export default function PlayoffBracket() {
  const [mounted, setMounted] = useState(false);
  const [games, setGames] = useState<Game[]>(INITIAL_GAMES);
  const [selections, setSelections] = useState<string[]>(Array(13).fill(''));
  const { address } = useAccount();

  const { writeContract } = useWriteContract();

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  const handleTeamSelect = (gameId: number, team: string) => {
    const gameIndex = gameId - 1;
    const previousSelection = selections[gameIndex];
    
    // Only proceed if this is a new selection or changing an existing one
    if (team !== previousSelection) {
      const newSelections = [...selections];
      newSelections[gameIndex] = team;
      setSelections(newSelections);

      // Update next round's matchup
      const currentGame = games.find(g => g.id === gameId);
      if (currentGame) {
        const nextRoundGame = getNextRoundGame(gameId, currentGame.round);
        if (nextRoundGame) {
          const isFirstTeam = isFirstTeamInNextRound(gameId);
          const updatedGames = games.map(g => {
            if (g.id === nextRoundGame) {
              // Don't override Chiefs or Lions in divisional round
              if ((g.id === 7 && g.team1 === 'Chiefs') || (g.id === 9 && g.team1 === 'Lions')) {
                return {
                  ...g,
                  team2: team
                };
              }
              // If this was a change of selection, clear the next round's corresponding slot
              if (previousSelection) {
                return {
                  ...g,
                  [isFirstTeam ? 'team1' : 'team2']: team
                };
              }
              // For new selections, only fill empty slots
              if (isFirstTeam && !g.team1) {
                return {
                  ...g,
                  team1: team
                };
              }
              if (!isFirstTeam && !g.team2) {
                return {
                  ...g,
                  team2: team
                };
              }
              return g;
            }
            return g;
          });
          setGames(updatedGames);
        }
      }
    }
  };

  const getNextRoundGame = (gameId: number, round: number): number | null => {
    if (round === 4) return null;
    
    // First round mappings
    if (round === 1) {
      // AFC side
      if (gameId === 1) return 7;      // Game 1 winner plays Chiefs
      if (gameId === 2) return 8;      // Game 2 and 3 winners play each other
      if (gameId === 3) return 8;
      // NFC side
      if (gameId === 4) return 9;      // Game 4 winner plays Lions
      if (gameId === 5) return 10;     // Game 5 and 6 winners play each other
      if (gameId === 6) return 10;
    }
    // Divisional round mappings
    else if (round === 2) {
      // AFC Championship
      if (gameId === 7) return 11;     // Chiefs bracket winner
      if (gameId === 8) return 11;     // Other AFC divisional winner
      // NFC Championship
      if (gameId === 9) return 12;     // Lions bracket winner
      if (gameId === 10) return 12;    // Other NFC divisional winner
    }
    // Conference Championships to Super Bowl
    else if (round === 3) {
      if (gameId === 11) return 13;    // AFC Champion
      if (gameId === 12) return 13;    // NFC Champion
    }
    return null;
  };

  const isFirstTeamInNextRound = (gameId: number): boolean => {
    return gameId % 2 !== 0;
  };

  const formatBracketSelections = () => {
    const bracketSelections = [];
    
    // Round 1 winners (first 6)
    for (let i = 0; i < 6; i++) {
      bracketSelections.push(selections[i]);
    }
    
    // Round 2 winners (next 4)
    for (let i = 6; i < 10; i++) {
      bracketSelections.push(selections[i]);
    }
    
    // Round 3 winners (next 2)
    bracketSelections.push(selections[10]);
    bracketSelections.push(selections[11]);
    
    // Super Bowl winner
    bracketSelections.push(selections[12]);

    return bracketSelections;
  };

  const calls = [{
    address: onchainPlayoffBracketContract as `0x${string}`,
    abi: OnchainPlayoffBracketAbi,
    functionName: 'createBracket',
    args: [formatBracketSelections()],
    value: parseEther('0.000001')
  }];

  return (
    <div className="flex flex-col items-center p-8">
      <div className="relative flex justify-center w-full gap-16">
        {/* AFC (Left) Side */}
        <div className="flex-1">
          <h2 className="text-2xl font-bold mb-8 text-center text-red-600">AFC</h2>
          <div className="flex gap-16">
            {/* Round 1 */}
            <div className="space-y-8">
              {games.slice(0, 3).map(game => (
                <div key={game.id} className="flex items-center">
                  <div className="border p-2 w-48">
                    <button
                      className={`w-full p-1 mb-1 ${
                        selections[game.id - 1] === game.team1
                          ? 'bg-red-500 text-white'
                          : 'hover:bg-gray-100'
                      }`}
                      onClick={() => handleTeamSelect(game.id, game.team1)}
                    >
                      {game.team1}
                    </button>
                    <button
                      className={`w-full p-1 ${
                        selections[game.id - 1] === game.team2
                          ? 'bg-red-500 text-white'
                          : 'hover:bg-gray-100'
                      }`}
                      onClick={() => handleTeamSelect(game.id, game.team2)}
                    >
                      {game.team2}
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* Round 2 */}
            <div className="space-y-16">
              {games.slice(6, 8).map(game => (
                <div key={game.id} className="border p-2 w-48">
                  <button
                    className={`w-full p-1 mb-1 ${
                      selections[game.id - 1] === game.team1
                        ? 'bg-red-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team1)}
                    disabled={!game.team1}
                  >
                    {game.team1 || '---'}
                  </button>
                  <button
                    className={`w-full p-1 ${
                      selections[game.id - 1] === game.team2
                        ? 'bg-red-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team2)}
                    disabled={!game.team2}
                  >
                    {game.team2 || '---'}
                  </button>
                </div>
              ))}
            </div>

            {/* Round 3 */}
            <div className="self-center">
              {games.slice(10, 11).map(game => (
                <div key={game.id} className="border p-2 w-48">
                  <button
                    className={`w-full p-1 mb-1 ${
                      selections[game.id - 1] === game.team1
                        ? 'bg-red-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team1)}
                    disabled={!game.team1}
                  >
                    {game.team1 || '---'}
                  </button>
                  <button
                    className={`w-full p-1 ${
                      selections[game.id - 1] === game.team2
                        ? 'bg-red-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team2)}
                    disabled={!game.team2}
                  >
                    {game.team2 || '---'}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Super Bowl (Center) */}
        <div className="self-center">
          <h2 className="text-2xl font-bold mb-4 text-center">Super Bowl</h2>
          <div className="border p-2 w-48">
            {games.slice(12, 13).map(game => (
              <div key={game.id}>
                <button
                  className={`w-full p-1 mb-1 ${
                    selections[game.id - 1] === game.team1
                      ? 'bg-purple-500 text-white'
                      : 'hover:bg-gray-100'
                  }`}
                  onClick={() => handleTeamSelect(game.id, game.team1)}
                  disabled={!game.team1}
                >
                  {game.team1 || '---'}
                </button>
                <button
                  className={`w-full p-1 ${
                    selections[game.id - 1] === game.team2
                      ? 'bg-purple-500 text-white'
                      : 'hover:bg-gray-100'
                  }`}
                  onClick={() => handleTeamSelect(game.id, game.team2)}
                  disabled={!game.team2}
                >
                  {game.team2 || '---'}
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* NFC (Right) Side */}
        <div className="flex-1">
          <h2 className="text-2xl font-bold mb-8 text-center text-blue-600">NFC</h2>
          <div className="flex gap-16 justify-end">
            {/* Round 3 */}
            <div className="self-center">
              {games.slice(11, 12).map(game => (
                <div key={game.id} className="border p-2 w-48">
                  <button
                    className={`w-full p-1 mb-1 ${
                      selections[game.id - 1] === game.team1
                        ? 'bg-blue-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team1)}
                    disabled={!game.team1}
                  >
                    {game.team1 || '---'}
                  </button>
                  <button
                    className={`w-full p-1 ${
                      selections[game.id - 1] === game.team2
                        ? 'bg-blue-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team2)}
                    disabled={!game.team2}
                  >
                    {game.team2 || '---'}
                  </button>
                </div>
              ))}
            </div>

            {/* Round 2 */}
            <div className="space-y-16">
              {games.slice(8, 10).map(game => (
                <div key={game.id} className="border p-2 w-48">
                  <button
                    className={`w-full p-1 mb-1 ${
                      selections[game.id - 1] === game.team1
                        ? 'bg-blue-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team1)}
                    disabled={!game.team1}
                  >
                    {game.team1 || '---'}
                  </button>
                  <button
                    className={`w-full p-1 ${
                      selections[game.id - 1] === game.team2
                        ? 'bg-blue-500 text-white'
                        : 'hover:bg-gray-100'
                    }`}
                    onClick={() => handleTeamSelect(game.id, game.team2)}
                    disabled={!game.team2}
                  >
                    {game.team2 || '---'}
                  </button>
                </div>
              ))}
            </div>

            {/* Round 1 */}
            <div className="space-y-8">
              {games.slice(3, 6).map(game => (
                <div key={game.id} className="flex items-center">
                  <div className="border p-2 w-48">
                    <button
                      className={`w-full p-1 mb-1 ${
                        selections[game.id - 1] === game.team1
                          ? 'bg-blue-500 text-white'
                          : 'hover:bg-gray-100'
                      }`}
                      onClick={() => handleTeamSelect(game.id, game.team1)}
                    >
                      {game.team1}
                    </button>
                    <button
                      className={`w-full p-1 ${
                        selections[game.id - 1] === game.team2
                          ? 'bg-blue-500 text-white'
                          : 'hover:bg-gray-100'
                      }`}
                      onClick={() => handleTeamSelect(game.id, game.team2)}
                    >
                      {game.team2}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {!address ? (
        <ConnectWallet 
          className="mt-16 px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
        >
          Connect Wallet
        </ConnectWallet>
      ) : (
        <Transaction
          chainId={baseSepolia.id}
          calls={calls}
          onStatus={(status) => console.log('Transaction status:', status)}
          onError={(err) => console.log('Transaction error:', err)}
          onSuccess={(receipt) => console.log('Transaction success:', receipt)}
        >
          <TransactionButton 
            className="mt-16 px-6 py-3 bg-green-500 text-white rounded-lg disabled:opacity-50"
            disabled={!selections.every(selection => selection !== '')}
            text="Submit Bracket (0.000001 ETH)"
          />
          <TransactionStatus>
            <TransactionStatusLabel />
            <TransactionStatusAction />
          </TransactionStatus>
        </Transaction>
      )}
    </div>
  );
} 