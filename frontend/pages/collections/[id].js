// NOTE: This component might not even be used
function Collection() {
  const router = useRouter();

  // NOTE: This ID will be used to query the smart contract
  
  const { id } = router.query;
  const [open, setOpen] = useState(false);

  const handleOpen = () => {
    setOpen(!open);
  };
  return (
    <>
      <div className="flex justify-center items-center h-screen">
        <img className="flex-1 p-80" src="/bagplaceholder2.png" alt="" />
        <div className="flex-1 p-20">
          <div className="pb-5">
            <h1 className="text-8xl font-bold text-black">{dummyData.name}</h1>
            <h1 className="text-lg text-slate-300">Owner: {dummyData.owner}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">DESCRIPTION</h1>
            <h1>{dummyData.description}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">MATERIAL</h1>
            <h1>{dummyData.material}</h1>
          </div>
          <div className="pb-5">
            <h1 className="text-xl font-bold">DIMENSIONS</h1>
            <h1>{dummyData.dimension}</h1>
          </div>
          <div>
            <button
              type="button"
              className="text-gray-800 bg-slate-50 focus:ring-4 ring-slate-800 font-medium text-sm px-5 py-2.5 text-center mr-2 mb-2 ring-2"
              onClick={handleOpen}
            >
              BUY FOR {dummyData.price} MATIC
            </button>
          </div>
        </div>
      </div>
      {/* <PurchaseDialog
        open={open}
        handleOpen={handleOpen}
        itemImage={"/bagplaceholder2.png"}
      /> */}
    </>
  );
}

export default Collection