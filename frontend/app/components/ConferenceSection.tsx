'use client';

import RoundSection from './RoundSection';

interface Game {
  id: number;
  round: number;
  team1: string;
  team2: string;
}

interface ConferenceSectionProps {
  conference: 'afc' | 'nfc';
  games: Game[];
  selections: string[];
  onTeamSelect: (gameId: number, team: string) => void;
}

export default function ConferenceSection({ 
  conference, 
  games, 
  selections, 
  onTeamSelect 
}: ConferenceSectionProps) {
  const isAFC = conference === 'afc';
  
  // Filter games by conference
  const wildcardGames = games.filter(g => 
    g.round === 1 && (isAFC ? g.id <= 3 : g.id >= 4 && g.id <= 6)
  );
  
  const divisionalGames = games.filter(g => 
    g.round === 2 && (isAFC ? g.id <= 8 : g.id >= 9 && g.id <= 10)
  );
  
  const conferenceGame = games.filter(g => 
    g.round === 3 && (isAFC ? g.id === 11 : g.id === 12)
  );

  const conferenceColor = isAFC ? 'text-red-600' : 'text-blue-600';
  const conferenceName = isAFC ? 'AFC' : 'NFC';

  return (
    <div className="flex-1">
      <h2 className={`text-2xl font-bold mb-8 text-center ${conferenceColor}`}>
        {conferenceName}
      </h2>
      <div className={`flex gap-16 ${isAFC ? '' : 'justify-end'}`}>
        {isAFC ? (
          <>
            <RoundSection
              title="Wildcard"
              games={wildcardGames}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
            />
            <RoundSection
              title="Divisional"
              games={divisionalGames}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
              spacing="wide"
            />
            <RoundSection
              title="Conference"
              games={conferenceGame}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
            />
          </>
        ) : (
          <>
            <RoundSection
              title="Conference"
              games={conferenceGame}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
            />
            <RoundSection
              title="Divisional"
              games={divisionalGames}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
              spacing="wide"
            />
            <RoundSection
              title="Wildcard"
              games={wildcardGames}
              selections={selections}
              onTeamSelect={onTeamSelect}
              conference={conference}
            />
          </>
        )}
      </div>
    </div>
  );
}
