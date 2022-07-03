import globalHook from "use-global-hook";
import { actions } from "./actions";

const initialState = {
  account: null,
  did: undefined,
  name: null,
  imageURL: null,
  network: "mumbai",
};

export const useGlobal = globalHook(initialState, actions);
