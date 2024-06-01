// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {FunctionsClient} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract PriceStables is FunctionsClient, ConfirmedOwner {
    AggregatorV3Interface internal dataFeed;
    
    mapping(string => address) public priceAddresses;
    mapping(string => int256) public stablesPrice;

    using FunctionsRequest for FunctionsRequest.Request;
    address router = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;
    
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {

        priceAddresses["USDC"] = 0x1b8739bB4CdF0089d07097A9Ae5Bd274b29C6F16;
        priceAddresses["EUR"] = 0xa73B1C149CB4a0bf27e36dE347CBcfbe88F65DB2;

    }

    /**
     * Set the latest price answer.
    */
    function getPrice(string memory token) public returns (int256) {
        int256 price = 0;
        address p_addr =  priceAddresses[token];

        if(p_addr != address(0)){
            dataFeed = AggregatorV3Interface(p_addr);
            price =  getChainlinkDataFeedLatestAnswer(token);
            price =  1e14 / price;
        }

        return  price;
    }


    function setAddress(string memory token, address p_address) public{
        priceAddresses[token] = p_address;
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer(string memory token) internal returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
         stablesPrice[token] = 1e14 / answer ;
        return answer;
    }



    // JavaScript source code
    // Fetch Rates API.
    string source =
        "const ethers = await import('npm:ethers@6.10.0');"
        "if(!secrets.GET_GEO_API_KEY || !secrets.ALPHA_API_KEY)"
        "   throw Error('Missed API key')"
        "const fromSymbol = args[0];"
        "const toSymbols = args[1];"
        "const url2 = `https://api.getgeoapi.com/v2/currency/convert`;"
        "const url3 = `https://www.alphavantage.co/query`;"
        "const getgeoapiRequest = Functions.makeHttpRequest({"
        "  url: url2,"
        "  headers: {"
        "    'Content-Type': 'application/json',"
        "  },"
        "  params: {"
        "    from: fromSymbol,"
        "    to: toSymbols,"
        "    amount: 1,"
        "    format: 'json',"
        "    api_key: secrets.GET_GEO_API_KEY"
        "  },"
        "});"
        "const apilayerRequest = Functions.makeHttpRequest({"
        "  url: url3,"
        "  headers: {"
        "    'Content-Type': 'application/json',"
        "  },"
        "  params: {"
        "    from_currency: fromSymbol,"
        "    to_currency: toSymbols,"
        "    function: 'CURRENCY_EXCHANGE_RATE',"
        "    apikey: secrets.ALPHA_API_KEY"
        "  },"
        "});"
        "const getgeoapiResponse = await getgeoapiRequest;"
        "const apilayerResponse = await apilayerRequest;"
        "if (getgeoapiResponse.error) {"
        "  console.error(getgeoapiResponse.error);"
        "  throw Error('getgeoapiResponse failed');"
        "}"
        "if (apilayerResponse.error) {"
        "  console.error(apilayerResponse.error);"
        "  throw Error('apilayerResponse failed');"
        "}"
        "const getgeoapiData = getgeoapiResponse['data'];"
        "const apilayerData = apilayerResponse['data'];"
        "if (getgeoapiData.Response === 'Error') {"
        "  console.error(getgeoapiData.Message);"
        "  throw Error("
        "    `Functional error. getgeoapiData Read message: ${getgeoapiData.Message}`"
        "  );"
        "}"
        "if (apilayerData.Response === 'Error') {"
        "  console.error(apilayerData.Message);"
        "  throw Error("
        "    `Functional error. apilayerData Read message: ${apilayerData.Message}`"
        "  );"
        "}"
        "let getgeoapiResults = getgeoapiData['rates'];"
        "let apilayerResults = {};"
        "apilayerResults[toSymbols] ="
        "  apilayerData['Realtime Currency Exchange Rate']['5. Exchange Rate'];"
        "for (const [key, value] of Object.entries(getgeoapiResults)) {"
        "  getgeoapiResults[key] = parseInt("
        "    parseFloat(getgeoapiResults[key]['rate']) * 1000000"
        "  );"
        "}"
        "for (const [key, value] of Object.entries(apilayerResults)) {"
        "  apilayerResults[key] = parseInt(parseFloat(apilayerResults[key]) * 1000000);"
        "}"
        "const arrayList = [getgeoapiResults, apilayerResults];"
        "let finalResults = {};"
        "const keys = [];"
        "const values = [];"
        "for (const [key, value] of Object.entries(getgeoapiResults)) {"
        "  const repVal = parseInt((getgeoapiResults[key] + apilayerResults[key]) / 2);"
        "  if (repVal > 0) {"
        "    keys.push(key);"
        "    values.push(repVal);"
        "  }"
        "}"
        "const encoded = ethers.AbiCoder.defaultAbiCoder().encode("
        "  ['string', 'int256'],"
        "  [keys[0], values[0]]"
        ");"
        "return ethers.getBytes(encoded);";


    uint32 gasLimit = 300000;

    // donID - Hardcoded for Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    
    bytes32 donID =
        0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;

   
    uint64 subscriptionId = 180;
    
    
    /**
     * @notice Send a simple request

     * @param encryptedSecretsUrls Encrypted URLs where to fetch user secrets
     * @param donHostedSecretsSlotID Don hosted secrets slotId
     * @param donHostedSecretsVersion Don hosted secrets version
     * @param args List of arguments accessible from within the source code
     * @param bytesArgs Array of bytes arguments, represented as hex strings
     */
    
    function sendRequest(
        // string memory source,
        bytes memory encryptedSecretsUrls,
        uint8 donHostedSecretsSlotID,
        uint64 donHostedSecretsVersion,
        string[] memory args,
        bytes[] memory bytesArgs
        // uint64 subscriptionId
        // ,
        // uint32 gasLimit,
        // bytes32 donID
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (encryptedSecretsUrls.length > 0)
            req.addSecretsReference(encryptedSecretsUrls);
        else if (donHostedSecretsVersion > 0) {
            req.addDONHostedSecrets(
                donHostedSecretsSlotID,
                donHostedSecretsVersion
            );
        }
        if (args.length > 0) req.setArgs(args);
        if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    /**
     * @notice Send a pre-encoded CBOR request
     * @return requestId The ID of the sent request
     */
    function sendRequestCBOR(
        bytes memory request
    ) external onlyOwner returns (bytes32 requestId) {
        s_lastRequestId = _sendRequest(
            request,
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;

        (string memory name, int256  price) = abi.decode(bytes(response), (string, int256));

      
        stablesPrice[name] =  int256 (price);
        

        emit Response(requestId, s_lastResponse, s_lastError);
    }
}
