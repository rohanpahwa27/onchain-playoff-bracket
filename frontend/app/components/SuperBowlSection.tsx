'use client';

import GameCard from './GameCard';

interface Game {
  id: number;
  round: number;
  team1: string;
  team2: string;
}

interface SuperBowlSectionProps {
  game: Game;
  selectedWinner: string;
  onTeamSelect: (gameId: number, team: string) => void;
}

export default function SuperBowlSection({ 
  game, 
  selectedWinner, 
  onTeamSelect 
}: SuperBowlSectionProps) {
  return (
    <div className="self-center">
      <h2 className="text-2xl font-bold mb-4 text-center">Super Bowl</h2>
      <GameCard
        gameId={game.id}
        team1={game.team1}
        team2={game.team2}
        selectedWinner={selectedWinner}
        onTeamSelect={onTeamSelect}
        conference="superbowl"
        disabled={!game.team1 || !game.team2}
      />
    </div>
  );
}
