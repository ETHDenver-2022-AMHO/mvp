 export const stripIpfsUriPrefix = (cidOrURI) => {
    if (cidOrURI.startsWith('ipfs://')) {
        return cidOrURI.slice('ipfs://'.length)
    }
    return cidOrURI
}


export const appendIpfsRoot = (cid) => {
    return 'https://ipfs.io/ipfs/' + cid;
}

export const ensureIpfsUriPrefix = (cidOrURI) => {
    let uri = cidOrURI.toString()
    if (!uri.startsWith('ipfs://')) {
        uri = 'ipfs://' + cidOrURI
    }
    if (uri.startsWith('ipfs://ipfs/')) {
      uri = uri.replace('ipfs://ipfs/', 'ipfs://')
    }
    return uri
}