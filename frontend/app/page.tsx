import dynamic from 'next/dynamic';

const PlayoffBracket = dynamic(
  () => import('./components/PlayoffBracket'),
  { ssr: false }
);

export default function Page() {
  return <PlayoffBracket />;
}