'use client';

interface GameCardProps {
  gameId: number;
  team1: string;
  team2: string;
  selectedWinner: string;
  onTeamSelect: (gameId: number, team: string) => void;
  conference: 'afc' | 'nfc' | 'superbowl';
  disabled?: boolean;
}

export default function GameCard({ 
  gameId, 
  team1, 
  team2, 
  selectedWinner, 
  onTeamSelect, 
  conference,
  disabled = false 
}: GameCardProps) {
  const getButtonStyle = (team: string) => {
    const isSelected = selectedWinner === team;
    const baseStyle = "w-full p-1 transition-colors duration-200";
    
    if (disabled && !team) {
      return `${baseStyle} bg-gray-100 text-gray-400 cursor-not-allowed`;
    }
    
    if (isSelected) {
      switch (conference) {
        case 'afc':
          return `${baseStyle} bg-red-500 text-white`;
        case 'nfc':
          return `${baseStyle} bg-blue-500 text-white`;
        case 'superbowl':
          return `${baseStyle} bg-purple-500 text-white`;
      }
    }
    
    return `${baseStyle} hover:bg-gray-100 ${disabled ? 'cursor-not-allowed' : 'cursor-pointer'}`;
  };

  return (
    <div className="border p-2 w-48">
      <button
        className={`${getButtonStyle(team1)} mb-1`}
        onClick={() => !disabled && team1 && onTeamSelect(gameId, team1)}
        disabled={disabled || !team1}
      >
        {team1 || '---'}
      </button>
      <button
        className={getButtonStyle(team2)}
        onClick={() => !disabled && team2 && onTeamSelect(gameId, team2)}
        disabled={disabled || !team2}
      >
        {team2 || '---'}
      </button>
    </div>
  );
}
