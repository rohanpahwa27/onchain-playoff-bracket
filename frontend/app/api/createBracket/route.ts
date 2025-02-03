// import { createWalletClient, http, parseEther } from 'viem';
// import { privateKeyToAccount } from 'viem/accounts';
// import { baseSepolia } from 'viem/chains';
// import { NextResponse } from 'next/server';
// import { onchainPlayoffBracketContract, OnchainPlayoffBracketAbi } from '../../lib/OnchainPlayoffBracket';

// export async function POST(req: Request) {
//   try {
//     const body = await req.json();
//     const { selections, userAddress } = body;

//     if (!selections || selections.length !== 13) {
//       return NextResponse.json({ error: 'Invalid selections' }, { status: 400 });
//     }

//     const privateKey = process.env.PRIVATE_KEY;
//     const account = privateKeyToAccount(privateKey as `0x${string}`);
    
//     const walletClient = createWalletClient({
//       account,
//       chain: baseSepolia,
//       transport: http()
//     });

//     const transactionHash = await walletClient.writeContract({
//       address: onchainPlayoffBracketContract,
//       abi: OnchainPlayoffBracketAbi,
//       functionName: 'createBracket',
//       args: [selections],
//       value: parseEther('0.000001')
//     });

//     return NextResponse.json({ transactionHash }, { status: 200 });
//   } catch (error) {
//     return NextResponse.json(
//       { error: 'Failed to create bracket', message: (error as Error).message },
//       { status: 500 }
//     );
//   }
// } 