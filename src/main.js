import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import voteAbi from '../contract/vote.abi.json'
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18

let kit
let contract
let candidates= [];

const MPContractAddress = "0x069A0Bb2670665ec490C1294864Bb8957253Cb38"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}

function candidateTemplate(_candidate) {
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_candidate.image}" alt="...">
      <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
        ${_candidate.votes} Votes
      </div>
      <div class="card-body text-left p-4 position-relative">
      <div class="translate-middle-y position-absolute top-0">
      ${identiconTemplate(_candidate.owner)}
      </div>
      <h2 class="card-title fs-4 fw-bold mt-2">${_candidate.name}</h2>
      <p class="card-text mb-4" style="min-height: 82px">
        ${_candidate.description}             
      </p>
      <div class="d-grid gap-2">
        <a class="btn btn-lg btn-outline-dark voteBtn fs-6 p-3" id=${
          _candidate.index
        }>
          Vote for ${_candidate.price} cUSD
        </a>
      </div>
    </div>
  </div>
`
}

async function renderCandidates() {
  document.getElementById("voting").innerHTML = ""
  console.log(candidates)
  candidates.forEach((_candidate) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = candidateTemplate(_candidate)
    document.getElementById("voting").appendChild(newDiv)
  })
}



const connectCeloWallet = async function () {
  if (window.celo) {
    try {
      notification("⚠️ Please approve this DApp to use it.")
      await window.celo.enable()
      notificationOff()
      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(voteAbi, MPContractAddress)

      console.log(contract)
    } catch (error) {
      console.log("error")
      notification(`⚠️ ${error.message}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}


const getBalance = async function () {
  
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.CELO.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getCandidates = async function() {
  const _candidatesLength = await contract.methods.getCandidatesLength().call();
  console.log(_candidatesLength)
  const _candidates = []
  for (let i = 0; i < _candidatesLength; i++) {
    let _candidate = new Promise(async (resolve, reject) => {
      let p = await contract.methods.readCandidate(i).call()
      console.log(p)
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        price: new BigNumber(p[4]),
        votes: p[5] ,
      })
    })
    _candidates.push(_candidate)
  }
  candidates = await Promise.all(_candidates)
  await renderCandidates()
}





function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}
function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}

document.querySelector("#voting").addEventListener("click", async (e) => {
  if (e.target.className.includes("voteBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for payment approval...")
    try {
      await approve(candidates[index].price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for "${candidates[index].name}"...`)
    try {
      const result = await contract.methods
        .vote(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully voted for "${candidates[index].name}".`)
      getCandidates()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})

document
  .querySelector("#newCandidateBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newCandidateName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newCandidateDescription").value,
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
      const result = await contract.methods
        .writeCandidate(...params)
        .send({ from: kit.defaultAccount })
     
       console.log(JSON.parse(result.status))
    } catch (error) {
      console.log(error)
      
      notification(`⚠️ ${error}.`)
    }


    notification(`🎉 You successfully added "${params[0]}".`)
    
    getCandidates()
  })



window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getCandidates();
 // renderCandidates()
  notificationOff()
})

