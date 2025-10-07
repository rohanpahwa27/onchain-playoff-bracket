'use client';

import GameCard from './GameCard';

interface Game {
  id: number;
  round: number;
  team1: string;
  team2: string;
}

interface RoundSectionProps {
  title: string;
  games: Game[];
  selections: string[];
  onTeamSelect: (gameId: number, team: string) => void;
  conference: 'afc' | 'nfc';
  spacing?: 'normal' | 'wide';
}

export default function RoundSection({ 
  title, 
  games, 
  selections, 
  onTeamSelect, 
  conference,
  spacing = 'normal'
}: RoundSectionProps) {
  const spacingClass = spacing === 'wide' ? 'space-y-16' : 'space-y-8';

  return (
    <div>
      <h3 className="text-lg font-semibold mb-4 text-center">{title}</h3>
      <div className={spacingClass}>
        {games.map(game => (
          <div key={game.id} className="flex items-center">
            <GameCard
              gameId={game.id}
              team1={game.team1}
              team2={game.team2}
              selectedWinner={selections[game.id - 1]}
              onTeamSelect={onTeamSelect}
              conference={conference}
              disabled={!game.team1 || !game.team2}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
