import { Status } from "./constants";
export const actions = {
  setAccount: (store, value) => {
    store.setState({ account: value });
  },
  setDID: (store, value) => {
    store.setState({ did: value });
  },
  setName: (store, value) => {
    store.setState({ name: value });
  },
  setImageURL: (store, value) => {
    store.setState({ imageURL: value });
  },
};
