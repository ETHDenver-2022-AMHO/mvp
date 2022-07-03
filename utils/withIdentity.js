import { Core } from '@self.id/core'
const SID = require('@self.id/web')
const { EthereumAuthProvider, SelfID, WebClient } = SID
import { selectImageSource } from '@self.id/image-utils'

// TODO: Set global hook to set the DID here

async function webClient({
  ceramicNetwork = 'testnet-clay',
  connectNetwork = 'testnet-clay',
  address = '',
  provider = null,
  client = null
} = {}) {
  let ethereum = window.ethereum;
  if (!ethereum) return {
    error: "No ethereum wallet detected"
  }

  if (!client) {
    client = new WebClient({
      ceramic: ceramicNetwork,
      connectNetwork
    })
  }

  if (!address) {
    [address] = await ethereum.request({ method: 'eth_requestAccounts' })
  }

  if (!provider) {
    provider = new EthereumAuthProvider(window.ethereum, address)
  }

  await client.authenticate(provider)

  const selfId = new SelfID({ client })
  const account = address;
  const id = selfId.did._id
  window.did = selfId.did;
  ceramic.did = selfId.did;

  return {
    account, client, id, selfId, error: null
  }
}

const networks = {
  ethereum: 'ethereum',
  mumbai: 'mumbai',
  fuji: 'fuji'
}

const caip10Links = {
  ethereum: "@eip155:1",
  mumbai: "@eip155:80001",
  fuji: "@eip155:43113",
}

async function getRecord({
  ceramicNetwork = 'testnet-clay',
  network = 'mumbai',
  client = null,
  schema = 'basicProfile',
  address = null
} = {}) {
  let ethereum = window.ethereum;
  let profile;

  if (!ethereum) return {
    error: "No ethereum wallet detected"
  }

  if (!client) {
    client = new Core({ ceramic: ceramicNetwork })
  }

  if (!address) {
   [address] = await ethereum.request({ method: 'eth_requestAccounts' })
  }
  const capLink = caip10Links[network]
  const did = await client.getAccountDID(`${address}${capLink}`)
  
  profile = await client.get(schema, did)

  const image = profile.image ? selectImageSource(profile.image, { width: 60, height: 60 }) : null

  let profileImage = selectImageSource(image);

  return {
    profile, did, image: profileImage, error: null
  }
}

export {
  webClient,
  getRecord
}