import { LayoutMargin } from "../components/Layout";
import { useEffect, useState } from "react";
// import { evmContractConditions } from "../utils/constants";
import { getEvmContractConditionsTemplate } from "../utils/constants";
import { useQRCode } from "next-qrcode";
import Amho from "../artifacts/contracts/Amho.sol/Amho.json";
import VRF from "../artifacts/contracts/VRFConsumer.sol/VRFConsumer.json";
import withLit from "../utils/withLit";

import { linkTokenAddress } from "../config";

const LinkArtifact = require("../artifacts/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol/LinkTokenInterface.json");
const LinkTokenABI = LinkArtifact.abi;

import { create } from "ipfs-http-client";
import { ethers } from "ethers";
import { CeramicClient } from "@ceramicnetwork/http-client";

import { nftAddress, vrfAddress } from "../config";

const client = create("https://ipfs.infura.io:5001/api/v0");

const preloadMintData = {
  name: "MUDANG",
  imageURI: undefined,
  description:
    "First leather bag created for ETHDenver 2022, built with pebble buffalo leather",
  dimension: "9.5 / 4.5 / 7.5 inches",
  material: "Pebble Grain Leather",
  price: 1,
  secretStream: "",
};

const Admin = ({ litCeramicIntegration }) => {
  const [ceramic, setCeramic] = useState(null);
  const [signer, setSigner] = useState(null);
  const [imageFileUrl, setImageFileUrl] = useState(null);
  const [finalSecretStream, setSecretStream] = useState(null);

  const [qrRef, setQrRef] = useState(null);
  const [metadataUrl, setMetadataUrl] = useState(null);
  const [metadata, setMetadata] = useState({
    ...preloadMintData,
  });

  const { Image } = useQRCode();

  useEffect(() => {
    if (typeof window !== "undefined") {
      const API_URL = "https://ceramic-clay.3boxlabs.com";
      const ceramic = new CeramicClient(API_URL);
      setCeramic(ceramic);
    }
  }, []);

  const getVRF = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    const signer = provider.getSigner();

    let vrfConsumer = new ethers.Contract(vrfAddress, VRF.abi, signer);

    let linkTokenContract = new ethers.Contract(
      linkTokenAddress,
      LinkTokenABI,
      signer
    );

    const tx = await linkTokenContract.transfer(
      vrfConsumer.address,
      "1000000000000000000"
    );
    await tx.wait();
    console.log("hash: ", tx.hash);
    let randomTransaction = await vrfConsumer.getRandomNumber();
    let tx_receipt = await randomTransaction.wait(1);
    const requestId = tx_receipt.events[2].topics[1];

    await new Promise((resolve) => setTimeout(resolve, 30000));

    let result = await vrfConsumer.randomResult();
    /**
     *
     *
     */
    const resultString = ethers.BigNumber.from(result._hex).toString();
    const hexString = ethers.BigNumber.from(result._hex).toHexString();

    return [resultString, hexString];
  };

  const encryptSecret = async (secretValue) => {
    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    const signer = provider.getSigner();

    let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);
    let currentTokenId = amhoContract.getCurrentTokenId();

    const tokenId = ethers.BigNumber.toString(currentTokenId);
    const evmContractConditions = getEvmContractConditionsTemplate(tokenId);

    console.log("TokenId ", tokenId);
    console.log("ecc", evmContractConditions);

    await litCeramicIntegration
      .encryptAndWrite(
        secretValue,
        evmContractConditions,
        "evmContractConditions"
      )
      .then((result) => {
        setSecretStream(result);
        return result;
      });
  };

  const imageUpload = async (e) => {
    const file = e.target.files[0];
    try {
      const added = await client.add(file, {
        progress: (prog) => console.log(`received: ${prog}`),
      });
      const url = `https://ipfs.infura.io/ipfs/${added.path}`;
      console.log(url);
      setImageFileUrl(url);
    } catch (error) {
      console.error("Error: ", error);
    }
  };

  const metadataUpload = async () => {
    const {
      name,
      description,
      dimension,
      material,
      price,
      imageURI = imageFileUrl,
      secretStream = finalSecretStream,
    } = metadata;

    const data = JSON.stringify({
      name,
      description,
      dimension,
      material,
      price,
      imageURI,
      secretStream,
    });

    try {
      const added = await client.add(data);
      const url = `https://ipfs.infura.io/ipfs/${added.path}`;
      setMetadataUrl(url);
      return url;
    } catch (error) {
      console.error("Error: ", error);
    }
  };

  const mintNft = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    const signer = provider.getSigner();

    let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);

    let [secret, hexSecret] = await getVRF();
    console.log("Secret: ", secret);
    console.log("hexSecret: ", hexSecret);

    await encryptSecret(secret);

    let hashedSecret = ethers.utils.solidityKeccak256(["bytes32"], [hexSecret]);

    const metadataURI = await metadataUpload();
    const price = ethers.BigNumber.from(metadata.price);

    let tx = await amhoContract.mintToken(hashedSecret, metadataURI, price);
    await tx.wait();
  };

  return (
    <div className={LayoutMargin}>
      <div className="pb-20">
        <div>
          <h1 className="text-8xl font-bold text-slate-200">MINT</h1>
        </div>

        <div className="pt-5">
          {imageFileUrl && (
            <video src={imageFileUrl} height={800} width={400} autoPlay loop />
          )}
          <input type="file" name="Asset" onChange={imageUpload} />
        </div>

        <div>
          <button
            onClick={mintNft}
            className="w-full focus:ring-4 ring-slate-800 ring-2 dark:text-gray-800 dark:bg-slate-50 sm:w-auto mt-14 text-base leading-4 text-center text-white py-6 px-16 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-800 bg-gray-800"
          >
            MINT
          </button>
        </div>
        <div>
          {finalSecretStream && (
            <div className="mt-10">
              <Image
                text={finalSecretStream}
                options={{
                  type: "image/jpeg",
                  quality: 0.9,
                  level: "M",
                  margin: 3,
                  scale: 4,
                  width: 200,
                  color: {
                    dark: "#000000FF",
                    light: "#FFFFFFFF",
                  },
                }}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default withLit(Admin);
