export const formatDid = (didString) => {
    return `${didString.slice(0,9)}...${didString.slice(didString.length - 4, didString.length)}`;
}