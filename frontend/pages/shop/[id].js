import { useRouter } from "next/router";
import { useState, useEffect} from "react";
import { nftAddress, escrowAddress, maticAddress } from "../../config";
import { LayoutMargin } from "../../components/Layout";
import { ethers } from "ethers";
import axios from "axios";

import Escrow from "../../artifacts/contracts/Escrow.sol/Escrow.json";
import Amho from "../../artifacts/contracts/Amho.sol/Amho.json";
import MaticToken from "../../artifacts/contracts/Overrides/ERC20.sol/ERC20.json";

function ShopItem() {
  const router = useRouter();

  // NOTE: This ID will be used to query the smart contract

  const { id } = router.query;
  const [open, setOpen] = useState(false);
  const [item, setItem] = useState(null);
  const [loading, setLoading] = useState(true);
  const [localSigner, setSigner] = useState();

  const handleOpen = () => {
    setOpen(!open);
  };
    useEffect(async () => {
      // NOTE: Returns owned array
    if (typeof window !== "undefined") {
    return;
    }

      const provider = new ethers.providers.Web3Provider(
        window.ethereum,
        "any"
      );
      const signer = provider.getSigner();

      let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);
      let singleItem = await amhoContract.getNFTState(id);

      const {tokenId, itemState, currentOwner} = singleItem;

      const tokenURI = await amhoContract.tokenURI(tokenId);

      const metadata = await axios.get(tokenURI);

      const {name, imageURI, description, dimension, material, price, secretStream} = metadata.data;

      const resultSingleItem = {
        name,
        price: ethers.utils.formatUnits(price.toString(), 'wei'),
        tokenId,
        imageURI,
        status: itemState,
        description,
        dimension,
        material,
        owner: currentOwner
      }

      setItem(resultSingleItem);
      setLoading(false);
    }, [window.ethereum]);

  const handleBuy = async () => {

    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    const signer = provider.getSigner();

    let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);
    let maticContract = new ethers.Contract(maticAddress, MaticToken.abi, signer);
    let escrowContract = new ethers.Contract(escrowAddress, Escrow.abi, signer);

    const { tokenId, price } = item;
    const bnPrice = ethers.BigNumber.from(price);


    let tx = await maticContract.approve(escrowContract.address, bnPrice);
    await tx.wait();
    await amhoContract.depositTokenToEscrow(tokenId, bnPrice);


  }

  if (loading)
    return (
      <div className={LayoutMargin}>
        <h1 className="text-8xl font-bold text-slate-200">NO NFTs</h1>
      </div>
    );
  return (
    <>
      <div className="flex justify-center items-center h-screen">
        <video
          className="flex-1 p-80"
          src={item.imageURI}
          autoPlay
          loop
          muted
          height={800}
          width={450}
          type="video/mp4"
        />
        <div className="flex-1 p-20">
          <div className="pb-10">
            <h1 className="text-8xl font-bold text-black">{item.name}</h1>
            <h1 className="text-lg text-slate-300">Owner: {item.owner}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">DESCRIPTION</h1>
            <h1>{item.description}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">MATERIAL</h1>
            <h1>{item.material}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">DIMENSIONS</h1>
            <h1>{item.dimension}</h1>
          </div>
          <div>
            <button
              type="button"
              className="text-gray-800 bg-slate-50 focus:ring-4 ring-slate-800 font-medium text-sm px-5 py-2.5 text-center mr-2 mb-2 ring-2"
              onClick={handleBuy}
            >
              BUY FOR {item.price} MATIC
            </button>
          </div>
        </div>
      </div>
    </>
  );
}

export default ShopItem;
