import { useEffect } from "react";
import { useGlobal } from "../utils/global-state";
import { useState } from "react";
import { ethers } from "ethers";
import axios from "axios";
import { AntiLayoutMargin, LayoutMargin } from "../components/Layout";
import withLit from "../utils/withLit";
import IconTethered from "../components/Icons/IconTethered";
import IconPending from "../components/Icons/IconPending";

import { nftAddress, escrowAddress } from "../config";
import Amho from "../artifacts/contracts/Amho.sol/Amho.json";
import IconUntethered from "../components/Icons/IconUntethered";

const Collections = ({ litCeramicIntegration }) => {
  const [loggedInAddress, setLoggedInAddress] = useState("");
  const [loading, setLoading] = useState(true);
  const [owned, setOwned] = useState([]);
  const [pending, setPending] = useState([]);
  const [pendingTether, setPendingTether] = useState([]);
  // const [ownedItems, setOwnedItems] = useState([]);
  const [open, setOpen] = useState(false);
  const [qrOpen, setQrOpen] = useState(false);
  const [_tokenId, setTokenId] = useState(0);
  const [streamData, setStreamData] = useState(null);
  const [decryptedSecret, setDecryptedSecret] = useState(null);

  useEffect(async () => {
    if (typeof window !== "undefined") {
      const provider = new ethers.providers.Web3Provider(
        window.ethereum,
        "any"
      );
      const accounts = await provider.listAccounts();
      setLoggedInAddress(accounts[0]);
      const signer = provider.getSigner();
      let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);

      let owned = await amhoContract.fetchOwned();
      let pending = await amhoContract.fetchPendingInitOrders();
      let pendingTether = await amhoContract.fetchPendingTether();

      const resultOwned = await Promise.all(
        owned.map(async (i) => {
          const tokenURI = await amhoContract.tokenURI(i.tokenId);
          const metadata = await axios.get(tokenURI);
          let price = ethers.utils.formatUnits(i.price.toString(), "ether");
          let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            owner: i.currentOwner,
            imageURI: metadata.data.imageURI,
            status: i.itemState,
          };
          console.log(item);
          return item;
        })
      );

      const resultPending = await Promise.all(
        pending.map(async (i) => {
          const tokenURI = await amhoContract.tokenURI(i.tokenId);
          const metadata = await axios.get(tokenURI);
          let price = ethers.utils.formatUnits(i.price.toString(), "ether");
          let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            owner: i.currentOwner,
            nextOwner: i.nextOwner,
            imageURI: metadata.data.imageURI,
            status: i.itemState,
          };
          return item;
        })
      );

      const resultPendingTether = await Promise.all(
        pendingTether.map(async (i) => {
          const tokenURI = await amhoContract.tokenURI(i.tokenId);
          const metadata = await axios.get(tokenURI);
          let price = ethers.utils.formatUnits(i.price.toString(), "ether");
          let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            owner: i.currentOwner,
            nextOwner: i.nextOwner,
            imageURI: metadata.data.imageURI,
            status: i.itemState,
          };
          return item;
        })
      );

      console.log(resultOwned);
      setOwned(resultOwned);
      setPending(resultPending);
      setPendingTether(resultPendingTether);
      setLoading(false);
    }
  }, [window.ethereum]);

  const handleOpen = ({ id }) => {
    setOpen(!open);
  };

  const decryptSecret = async (qrData, type) => {
    await litCeramicIntegration
      .readAndDecrypt(qrData)
      .then(async (decryptedText) => {
        setDecryptedSecret(decryptedText);
        const secret = ethers.BigNumber.from(decryptedText);
        const hexSecret = ethers.utils.hexlify(secret);
        const soliditySecret = ethers.utils.solidityKeccak256(
          ["bytes32"],
          [hexSecret]
        );
        const tokenId = _tokenId;

        const provider = new ethers.providers.Web3Provider(
          window.ethereum,
          "any"
        );

        const signer = provider.getSigner();
        let amhoContract = new ethers.Contract(nftAddress, Amho.abi, signer);
        if (type == 2) {
          await amhoContract.releaseOrderToEscrow(tokenId, soliditySecret);
        } else {
          await amhoContract.depositNftToEscrow(tokenId, soliditySecret);
        }
      });
  };

  const handleQRTether = (tokenId, type) => {
    setTokenId(tokenId);
    let ethereum = window.ethereum;
    if (!ethereum) {
      console.log("No wallet detected");
    }

    ethereum
      .request({
        method: "wallet_scanQRCode",
        params: ["\\D"],
      })
      .then((result) => {
        decryptSecret(result, type);
      })
      .catch((error) => {
        console.log(error);
      });
  };
  const handleQRInit = (tokenId) => {
    setTokenId(tokenId);
    let ethereum = window.ethereum;
    if (!ethereum) {
      console.log("No wallet detected");
    }

    ethereum
      .request({
        method: "wallet_scanQRCode",
        params: ["\\D"],
      })
      .then((result) => {
        decryptSecret(result);
      })
      .catch((error) => {
        console.log(error);
      });
  };

  const CollectionItem = ({ item, id }) => {
    return (
      <div className="flex flex-col">
        <div className="flex justify-center">
          {item.status == 3 || item.status == 0 ? (
            <IconTethered />
          ) : item.status == 1 && item.owner == loggedInAddress ? (
            <a onClick={() => handleQRInit(item.tokenId)}>
              <IconPending status={item.status} id={id} />
            </a>
          ) : item.status == 1 && item.nextOwner == loggedInAddress ? (
            ""
          ) : item.status == 2 && item.nextOwner == loggedInAddress ? (
            <a onClick={() => handleQRTether(item.tokenId, item.status)}>
              <IconPending status={item.status} id={id} />
            </a>
          ) : (
            <IconUntethered />
          )}
        </div>
        <div className="grow">
          <video
            src={item.imageURI}
            preload
            autoPlay
            loop
            muted
            height={600}
            width={350}
            type="video/mp4"
          />
        </div>
      </div>
    );
  };

  if (loading && (!owned.length || !pending.length))
    return (
      <div className={LayoutMargin}>
        <h1 className="text-8xl font-bold text-slate-200">NO NFTs</h1>
      </div>
    );

  return (
    <div className={LayoutMargin}>
      <div className="pb-20">
        {/*  NOTE: OWNED */}

        <h1 className="text-8xl font-bold text-slate-200">OWNED</h1>
      </div>
      <div className="flex flex-row flex-wrap justify-start items-stretch gap-60">
        {owned.map(
          (item, id) =>
            (item.status == 0 || item.status == 3) && (
              <CollectionItem item={item} id={id} />
            )
        )}
      </div>
      <div className="pt-10 pb-10 mt-60">
        {/* NOTE: ORDERS */}

        <h1 className="text-8xl font-bold text-slate-200">ORDERS</h1>
      </div>
      <div className="flex flex-row flex-wrap justify-start items-stretch gap-60">
        {pending.map(
          (item, id) =>
            item.status == 1 && <CollectionItem item={item} id={id} />
        )}
        {pendingTether.map(
          (item, id) =>
            item.status == 2 && <CollectionItem item={item} id={id} />
        )}
      </div>
    </div>
  );
};

export default withLit(Collections);
