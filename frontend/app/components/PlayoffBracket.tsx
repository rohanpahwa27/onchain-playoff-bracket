'use client';

import ConferenceSection from './ConferenceSection';
import SuperBowlSection from './SuperBowlSection';
import BracketSubmission from './BracketSubmission';
import BracketScores from './BracketScores';
import { useBracketLogic } from '../hooks/useBracketLogic';

export default function PlayoffBracket() {
  const { games, selections, handleTeamSelect, formatBracketSelections } = useBracketLogic();

  // Find the Super Bowl game
  const superBowlGame = games.find(g => g.round === 4)!;

  return (
    <div className="flex flex-col items-center p-8">
      <div className="relative flex justify-center w-full gap-16">
        <ConferenceSection
          conference="afc"
          games={games}
          selections={selections}
          onTeamSelect={handleTeamSelect}
        />

        <SuperBowlSection
          game={superBowlGame}
          selectedWinner={selections[superBowlGame.id - 1]}
          onTeamSelect={handleTeamSelect}
        />

        <ConferenceSection
          conference="nfc"
          games={games}
          selections={selections}
          onTeamSelect={handleTeamSelect}
        />
      </div>

      <BracketSubmission
        selections={selections}
        formatBracketSelections={formatBracketSelections}
      />

      <BracketScores />
    </div>
  );
} 