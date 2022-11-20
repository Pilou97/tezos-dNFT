import { TezosToolkit } from '@taquito/taquito';
import { InMemorySigner } from '@taquito/signer';
const config = require('config');

interface WeatherData {
    latitude: number,
    longitude: number,
    current_weather: {
        temperature: number,
        windspeed: number,
        winddirection: number,
        weathercode: number,
        time: String
      }
}

/**
 * Returns the temperature from open meteo for a given latitude and longitude.
 * @param latitude the first coordinate
 * @param longitude the second coordinate
 */
const GetTempFromOpenMeteo = (latitude: number, longitude: number): Promise<number> =>
    fetch(`https://api.open-meteo.com/v1/forecast?current_weather=true&`+
    `latitude=${latitude}&longitude=${longitude}&timezone=auto`)
    .then((resp) => resp.json())
    .then((res) => {
        return Math.round((res as WeatherData).current_weather.temperature)
    })

/**
 * Converts the metadata to a Michelson parameter
 */
const toPayload = ({key, temperature}) => {
    const hex = temperature.toString(16);
    const hexadecimal = (hex.length % 2 === 1) ? `0${hex}` : hex;
    return {
        token_id: key,
        metadata: {
            temperature: {
                update: hexadecimal
            }
        }
    }
}

/**
 * Returns the contract for a given address
 * @param tezos the TezosToolkit from Taquito
 * @param contract the KT1 address of the contract
 */
const getContract = (tezos:TezosToolkit, contract: string)  => tezos.contract.at(contract)

/**
 * Retrieves all the metadata of all the tokens in a FA2 contract.
 */
const getTokens = (contract:any) : Promise<Array<{key: number, longitude: number, latitude: number}>> => {
    return contract.storage()
        .then(storage => {
            const counter = storage["counter"].c[0];
            const keys = [... new Array(counter).keys()];
            const values = storage["token_metadata"].getMultipleValues(keys);
            const tokens = Object.fromEntries(values.valueMap);
            return Object.keys(tokens).map(key => {
                const metadata = Object.fromEntries(tokens[key].token_info.valueMap);
                const latitude = Number("0x" + metadata['"latitude"']) / 1_000_000;
                const longitude = Number("0x" + metadata['"longitude"']) / 1_000_000;
                const temperature = Number("0x" + metadata['"temperature"']);
                return {key, latitude, longitude, temperature};
            }, {})
        })
        .then(storage => {
            console.log(storage); // For debug purpose
            return storage
        });
}

/**
 * Returns the temperatures of a token collection
 * @param tokens the metadata of different tokens
 * @return the list of temperature with the id of the associated token
 */
const getTokenTemperatures = (tokens: Array<{key: number, latitude: number, longitude: number}>): Promise<Array<{key: number, temperature: number}>> => {
    return Promise.all(tokens.map(({key, latitude, longitude}) =>
        GetTempFromOpenMeteo(latitude, longitude)
        .then(temperature => ({key, temperature}))
    ));
}

/**
 * Function that updates the contract.
 * It fetches all the existing tokens
 * It fetches the new temperatures
 * And commit to Tezos only the updated temperatures
 */
const updateContract = async (tezos: any, contractAddress:string): Promise<null> => {
    const contract = await getContract(tezos, contractAddress);
    const tokens = await getTokens(contract);
    const newTemperatures = await getTokenTemperatures(tokens);
    const tokensToUpdate = newTemperatures
        .filter(({key, temperature}) => {
            const token:any = tokens.find(({key:token_id}) => token_id === key);
            return token.temperature !== temperature
        })
        .map(toPayload);
    if (tokensToUpdate.length === 0) return null;
    await contract.methods.update_metadata(tokensToUpdate).send();
    console.log("update success");
    return null;
}

/**
 * Updates the contract every blocks.
 */
const updateLoop = (tezos: TezosToolkit, contract: string, ms: number) => {
    const loop = (prevBlock: string) => {
        tezos.rpc.getBlock()
        .then((blockresponse) => {
            if (blockresponse.hash !== prevBlock) {
                updateContract(tezos, contract)
            }
            setTimeout(loop, ms, blockresponse.hash)
        })
        .catch(console.error)
    }
    return loop("");
}

/**
 * Starts the update loop with the appropriate variables
 */
const main = ()  => {
    const tezos = new TezosToolkit(config.get("tezosEndpoint"));
    const Signer = new InMemorySigner(config.get("signer"))
    tezos.setProvider({
        signer: Signer
    });
    updateLoop(tezos, config.get("contract"), config.get("blockTime"))
}

main()
