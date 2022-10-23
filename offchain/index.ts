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

const GetTempFromOpenMeteo = (latitude, longitude: number) =>
    fetch(`https://api.open-meteo.com/v1/forecast?current_weather=true&`+
    `latitude=${latitude}&longitude=${longitude}&timezone=auto`)
    .then((resp) => resp.json())
    .then((res) => {
        return Math.round((res as WeatherData).current_weather.temperature)
    })



const balance = (tezos: TezosToolkit, signer: InMemorySigner) => {
    signer.publicKeyHash().then((address) => tezos.tz.getBalance(address)).then(console.log);
}

const toPayload = ({key, temperature}) => {
    const hex = temperature.toString(16);
    const hexa = (hex.length % 2 === 1) ? "0"+hex : hex;
    return {
        token_id: key,
        metadata: {
            "temperature": {update: hexa}
        }
    }
}

const getContract = (tezos:TezosToolkit, contract: string)  => tezos.contract.at(contract)


const getTokens = (contract:any) : Promise<Array<{key: number, longitude: number, latitude: number}>> => {
    return contract.storage()
        .then((storage:any) => {
            const counter = storage["counter"].c[0]; // Find a better way
            const keys = [... new Array(counter).keys()];
            return storage["token_metadata"].getMultipleValues(keys)
        })
        .then(tokens =>  Object.fromEntries(tokens.valueMap))
        .then(tokens => Object.keys(tokens).map(key => {
            const metadata = Object.fromEntries(tokens[key].token_info.valueMap);
            const latitude = Number("0x" + metadata['"latitude"']) / 1_000_000;
            const longitude = Number("0x" + metadata['"longitude"']) / 1_000_000;
            const temperature = Number("0x" + metadata['"temperature"']);
            return {key, latitude, longitude, temperature};
        }, {}))
        .then(tokens => {
            console.log(tokens);
            return tokens
        })
        // return contact.methods.update_metadata(toPayload(temp)).send();
}

const updateContract = async (tezos: any, contractAddress:string): Promise<null> => {
    const contract = await getContract(tezos, contractAddress);
    const tokens = await getTokens(contract);
    const newTemperatures = await Promise.all(tokens.map(({key, latitude, longitude}) =>
         GetTempFromOpenMeteo(latitude, longitude)
            .then(temperature => ({key, temperature}))
    ));
    // To test
    const tokenToUpdate = newTemperatures
        .filter(({key, temperature}) => {
            const token:any = tokens.find(({key:token_id}) => token_id === key);
            return token.temperature !== temperature
        });
    if (tokenToUpdate.length === 0) return null;
    const payload = tokenToUpdate.map(toPayload);
    const operation = await contract.methods.update_metadata(payload).send();
    console.log("update success");
    return null;
}

interface geo {
    longitude: number,
    latitude: number
}


const getGeosFromContract = (contract: any) : Promise<[geo]> => {
    return contract.storage().then((storage:any) => storage["token_metadata"].map((elt) => elt));
    // storage["token_metadata"]
}

// const updateTemp = (tezos: TezosToolkit, contract: string) => {
//     GetTempFromOpenMeteo(
//         50.63297,
//         3.05858
//     )
//     .then( (temp: number) => {console.log("got temp from openmeteo : "+temp); return loadContract(tezos, contract, temp)})
//     .then(operation => {
//         console.log("waiting for operation")
//         return operation.confirmation(1)
//     })
//     .catch(err => {
//         console.log("error");
//         console.error(err)
//     })
// }

const updateLoop = (tezos: TezosToolkit, contract: string, t: number) => {
    const loop = (prevBlock: string) => {
        tezos.rpc.getBlock()
        .then((blockresponse) => {
            if (blockresponse.hash !== prevBlock) {
                updateContract(tezos, contract)
            }
            setTimeout(loop, t, blockresponse.hash)
        })
        .catch(console.error)
    }
    loop("");
}

const main = ()  => {
    const tezos = new TezosToolkit(config.get("tezosEndpoint"));
    const Signer = new InMemorySigner(config.get("signer"))
    tezos.setProvider({
        signer: Signer
    });
    balance(tezos, Signer);

    updateLoop(tezos, config.get("contract"), config.get("blockTime"))
}



main()
