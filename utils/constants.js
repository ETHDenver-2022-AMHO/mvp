import { nftAddress as CONTRACT_ADDRESS } from "../config";


// prettier-ignore
export const Status = [
  "NEW",             // 0
  "PENDING_INIT",    // 1
  "PENDING_TETHER",  // 2
  "TETHERED",        // 3
  "UNTETHERED",      // 4
];

export const evmContractConditions = [
  {
    contractAddress: CONTRACT_ADDRESS,
    functionName: "getCurrentOwner",
    functionParams: ["0"],
    functionAbi: {
      inputs: [
        {
          internalType: "uint256",
          name: "_tokenId",
          type: "uint256"
        }
      ],
      name: "getCurrentOwner",
      outputs: [
        {
          internalType: "address",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    chain: "mumbai",
    returnValueTest: {
      key: "",
      comparator: "=",
      value: ":userAddress",
    },
  },
  { operator: "or" },
  {
    contractAddress: CONTRACT_ADDRESS,
    functionName: "getNextOwner",
    functionParams: ["0"],
    functionAbi: {
      inputs: [
        {
          internalType: "uint256",
          name: "_tokenId",
          type: "uint256"
        }
      ],
      name: "getNextOwner",
      outputs: [
        {
          internalType: "address",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    chain: "mumbai",
    returnValueTest: {
      key: "",
      comparator: "=",
      value: ":userAddress",
    },
  },
];

export const getEvmContractConditionsTemplate = (_tokenId) => {
  return [
  {
    contractAddress: CONTRACT_ADDRESS,
    functionName: "getCurrentOwner",
    functionParams: [`${_tokenId}`],
    functionAbi: {
      inputs: [
        {
          internalType: "uint256",
          name: "_tokenId",
          type: "uint256"
        }
      ],
      name: "getCurrentOwner",
      outputs: [
        {
          internalType: "address",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    chain: "mumbai",
    returnValueTest: {
      key: "",
      comparator: "=",
      value: ":userAddress",
    },
  },
  { operator: "or" },
  {
    contractAddress: CONTRACT_ADDRESS,
    functionName: "getNextOwner",
    functionParams: [`${_tokenId}`],
    functionAbi: {
      inputs: [
        {
          internalType: "uint256",
          name: "_tokenId",
          type: "uint256"
        }
      ],
      name: "getNextOwner",
      outputs: [
        {
          internalType: "address",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    chain: "mumbai",
    returnValueTest: {
      key: "",
      comparator: "=",
      value: ":userAddress",
    },
  },
];
}

