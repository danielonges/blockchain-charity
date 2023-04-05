const _deploy_contracts = require('../migrations/2_deploy_contracts')
const truffleAssert = require('truffle-assertions')
var assert = require('assert')

var Charity = artifacts.require('../contracts/Charity.sol')
var CharityStorage = artifacts.require('../contracts/CharityStorage.sol')
var DonorStorage = artifacts.require('../contracts/DonorStorage.sol')
var Donor = artifacts.require('../contracts/Donor.sol')
var ProjectMarketStorage = artifacts.require(
  '../contracts/ProjectMarketStorage.sol'
)
var ProjectMarket = artifacts.require('../contracts/ProjectMarket.sol')
var CharityToken = artifacts.require('../contracts/CharityToken.sol')

const { time } = require('@openzeppelin/test-helpers')

const BigNumber = require('bignumber.js') // npm install bignumber.js

const oneEth = new BigNumber(1000000000000000000) // 1 eth

contract('ProjectMarket', function (accounts) {
  before(async () => {
    charityInstance = await Charity.deployed()
    charityStorageInstance = await CharityStorage.deployed()
    donorStorageInstance = await DonorStorage.deployed()
    donorInstance = await Donor.deployed()
    projectMarketStorageInstance = await ProjectMarketStorage.deployed()
    projectMarketInstance = await ProjectMarket.deployed()
    charityTokenInstance = await CharityToken.deployed()
  })
  console.log('Testing ProjectMarket Contract')

  // initialise testing constants
  const charity = {
    charityId: 0,
    name: 'Leonard Foundation',
    category: CharityStorage.charityCategory.CHILDREN,
    owner: accounts[1]
  }

  const donor1 = {
    donorAddr: accounts[2]
  }

  const donor2 = {
    donorAddr: accounts[3]
  }

  const donor3 = {
    donorAddr: accounts[4]
  }

  const charityId = 0
  const projectId = 0
  const project = {
    title: 'Project 1',
    description: 'Give Leonard Some Food',
    targetAmount: 100,
    charityId: 0,
    charityAddr: charity.owner,
    donorAddr: donor1.donorAddr
  }

  it('Verify Charity', async () => {
    let verifiedCharity = await charityInstance.verifyCharity(
      charity.owner,
      charity.name,
      charity.category,
      { from: accounts[0] }
    )

    // charity that is created has an ID of 0
    assert.ok(
      await charityInstance.isOwnerOfCharity(project.charityId, accounts[1])
    )

    truffleAssert.eventEmitted(
      verifiedCharity,
      'charityVerified',
      (ev) => ev.charity == accounts[1]
    )
  })

  it('Verify Donor', async () => {
    let verifiedDonor = await donorInstance.verifyDonor(donor1.donorAddr, {
      from: accounts[0]
    })

    // verify 2 more donors for testing
    await donorInstance.verifyDonor(donor2.donorAddr, {
      from: accounts[0]
    })

    await donorInstance.verifyDonor(donor3.donorAddr, {
      from: accounts[0]
    })

    // check that all 3 donors created are verified
    assert.ok(await donorInstance.isValidDonor(donor1.donorAddr))
    assert.ok(await donorInstance.isValidDonor(donor2.donorAddr))
    assert.ok(await donorInstance.isValidDonor(donor3.donorAddr))

    truffleAssert.eventEmitted(
      verifiedDonor,
      'donorVerified',
      (ev) => ev.donor == accounts[2]
    )
  })

  it('List Project', async () => {
    let listProject1 = await projectMarketInstance.listProject(
      project.charityId,
      project.title,
      project.description,
      project.targetAmount,
      {
        from: accounts[1]
      }
    )

    let listProject2 = await projectMarketInstance.listProject(
      project.charityId,
      'Project 2',
      'To be unlisted',
      project.targetAmount,
      {
        from: accounts[1]
      }
    )

    // only owning charity can list project
    await truffleAssert.reverts(
      projectMarketInstance.listProject(
        project.charityId,
        'Project Failed',
        'Failed test',
        100,
        {
          from: accounts[2]
        }
      ),
      'Only owning charity can perform this action!'
    )

    truffleAssert.eventEmitted(
      listProject1,
      'projectListed',
      (ev) => ev.charityId == project.charityId
    )
  })

  it('Unlist Project', async () => {
    let unlistProject = await projectMarketInstance.unlistProject(1, {
      from: accounts[1]
    })

    // isActive boolean flag for project ID 1 will be false
    assert.ok(!(await projectMarketInstance.isProjectActive(1)))

    // only owning charity can unlist project
    await truffleAssert.reverts(
      projectMarketInstance.unlistProject(projectId, {
        from: accounts[2]
      }),
      'Only owning charity can perform this action!'
    )

    truffleAssert.eventEmitted(
      unlistProject,
      'projectClosed',
      (ev) => ev.projectId == 1
    )
  })

  it('View all project listings', async () => {
    // returns a list of active projects
    let allProjects = await projectMarketInstance.getAllActiveProjectListings()
    const projectToCheck = allProjects[0]

    // there are 2 projects but only 1 is active
    assert.strictEqual(
      allProjects.length,
      1,
      'All projects length is not correct'
    )
    assert.ok(
      project.charityAddr,
      accounts[1],
      'Project listing owner is not correct'
    )
    assert.strictEqual(
      parseInt(projectToCheck.projectId),
      projectId,
      'Project ID is not correct'
    )
  })

  it('View Project Listing Details', async () => {
    let projectToCheck = await projectMarketInstance.getProjectListingDetails(
      projectId
    )

    assert.strictEqual(
      projectToCheck.title,
      project.title,
      'Project title is not correct'
    )
    assert.strictEqual(
      projectToCheck.description,
      project.description,
      'Project description is not correct'
    )
    assert.strictEqual(
      parseInt(projectToCheck.targetAmount),
      project.targetAmount,
      'Project target amount is not correct'
    )
    assert.strictEqual(
      parseInt(projectToCheck.projectId),
      projectId,
      'Project ID is not correct'
    )
    assert.strictEqual(
      parseInt(projectToCheck.charityId),
      project.charityId,
      "Project's charity ID is not correct"
    )
  })

  it('Donate to project', async () => {
    // donor 1 donates 50 tokens
    await donorInstance.getTokens({
      from: donor1.donorAddr,
      value: oneEth
    })
    await charityTokenInstance.approveTokenSpending(donor1.donorAddr, 50)
    let donateToProject = await projectMarketInstance.donateToProject(
      projectId,
      50,
      { from: donor1.donorAddr }
    )

    // donor 2 donates 40 tokens
    await donorInstance.getTokens({
      from: donor2.donorAddr,
      value: oneEth
    })
    await charityTokenInstance.approveTokenSpending(donor2.donorAddr, 40)
    await projectMarketInstance.donateToProject(projectId, 40, {
      from: donor2.donorAddr
    })

    // donor 3 donates 40 tokens
    await donorInstance.getTokens({
      from: donor3.donorAddr,
      value: oneEth
    })
    await charityTokenInstance.approveTokenSpending(donor3.donorAddr, 40)
    await projectMarketInstance.donateToProject(projectId, 40, {
      from: donor3.donorAddr
    })

    truffleAssert.eventEmitted(
      donateToProject,
      'donationMade',
      (ev) => ev.projectId == projectId && ev.donor == donor1.donorAddr
    )
    let balanceDonor = await donorInstance.checkTokenBalance({
      from: donor1.donorAddr
    })
    // donor 1 should only have 50 tokens left since he purchased 100 tokens and spent 50
    assert.strictEqual(
      balanceDonor.toNumber(),
      50,
      'Error donating to project!'
    )
  })

  it('Verify proof of donation', async () => {
    // charity submits proof of donation off the blockchain and contract owner verifies the proof on the blockchain
    let proofUpload = await projectMarketInstance.verifyProofOfUsage(
      projectId,
      100,
      'Food',
      { from: accounts[0] }
    )
    let proofsByProject = await projectMarketInstance.getProofsByProject(
      projectId
    )
    truffleAssert.eventEmitted(
      proofUpload,
      'proofVerified',
      (ev) => ev.projectId == projectId && ev.amount == 100
    )
    assert.strictEqual(
      proofsByProject.length,
      1,
      'Failed to view all donations by project'
    )
    // total amount verified for donation ID 0 is 50, the donation is fully verified
    assert.strictEqual(
      Number(await projectMarketInstance.getAmountVerifiedByDonation(0)),
      50,
      'Failed to view amount verified of donation ID 0'
    )
    assert.ok(
      Number(await projectMarketInstance.getTimeTakenToVerifyByDonation(0)) > 0,
      'Time taken to verify is not recorded for donation ID 0'
    )
    // total amount verified for donation ID 1 is 40, the donation is fully verified
    assert.strictEqual(
      Number(await projectMarketInstance.getAmountVerifiedByDonation(1)),
      40,
      'Failed to view amount verified of donation ID 1'
    )
    // if a donation is fully verified, time taken to verify will be > 0
    assert.ok(
      Number(await projectMarketInstance.getTimeTakenToVerifyByDonation(1)) > 0,
      'Time taken to verify is not recorded for donation ID 1'
    )
    // total amount verified for donation ID 2 is 10, since the proof's amount is only 100 tokens
    // after verifying the first 2 donations, there are only 10 tokens left to verify donation ID 2
    // the donation is partially verified
    assert.strictEqual(
      Number(await projectMarketInstance.getAmountVerifiedByDonation(2)),
      10,
      'Failed to view amount verified of donation ID 2'
    )
    // if a donation is not fully verified, time taken to verify will be == 0
    assert.ok(
      Number(await projectMarketInstance.getTimeTakenToVerifyByDonation(2)) ==
        0,
      'Time taken to verify is not recorded for donation ID 2'
    )
  })

  it('View all donations by project', async () => {
    let donationsByProject = await projectMarketInstance.getDonationsByProject(
      projectId
    )
    console.log('donationsByProject', donationsByProject)
    // 3 donations made for project ID 0
    assert.strictEqual(
      donationsByProject.length,
      3,
      'Failed to view all donations by project'
    )
  })

  it('View all proofs by project', async () => {
    let proofsByProject = await projectMarketInstance.getProofsByProject(
      projectId
    )
    // 1 proof verified for project ID 0
    assert.strictEqual(
      proofsByProject.length,
      1,
      'Failed to view all proof by project'
    )
  })

  it('View past donations by donor', async () => {
    let donationsByDonor = await projectMarketInstance.viewPastDonationsByDonor(
      { from: donor3.donorAddr }
    )
    // donor only made 1 donation
    assert.strictEqual(
      donationsByDonor.length,
      1,
      'Failed to view all donations by donor'
    )
  })

  it('Automatically lock charity wallet', async () => {
    // donor 1 donates 100 tokens to the charity
    await donorInstance.getTokens({
      from: donor1.donorAddr,
      value: oneEth.multipliedBy(2)
    })
    await charityTokenInstance.approveTokenSpending(donor1.donorAddr, 100)
    let donateToProject = await projectMarketInstance.donateToProject(
      projectId,
      100,
      { from: donor1.donorAddr }
    )

    // fast forward to 20 days after
    // if a charity has at least 100 tokens that are not verified after 20 days or more, the wallet will be locked
    await time.increase(await projectMarketInstance.unverifiedTimeLimit())

    // contract owner checks for unverified limit, and the lock should be activated
    let unverifiedDonationsExceeded =
      await projectMarketInstance.checkUnverifiedDonations(projectId, {
        from: accounts[0]
      })

    truffleAssert.eventEmitted(
      unverifiedDonationsExceeded,
      'unverifiedDonationsExceeded',
      (ev) => ev.charityId == charityId
    )

    const oldBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    )

    // try to withdraw tokens from the wallet, should not be allowed
    await truffleAssert.reverts(
      charityInstance.withdrawTokens(charityId, 100, {
        from: accounts[1]
      }),
      'Wallet is locked and tokens cannot be withdrawn'
    )

    const newBalance = new BigNumber(
      await charityInstance.checkTokenBalance(charityId, {
        from: accounts[1]
      })
    )

    assert.ok(oldBalance.isEqualTo(newBalance), 'Unlock Wallet not working')
  })

  it('View charity metrics', async () => {
    let charityDetails = await charityInstance.getCharityDetails(
      charity.charityId
    )
    console.log('charityDetails', charityDetails)
    // total verified transactions are donations ID 0 and 1
    assert.strictEqual(
      Number(
        await charityInstance.getNumVerifiedTransactions(charity.charityId)
      ),
      2,
      'Failed to view number of verified transactions'
    )
    // total unverified transactions is donation ID 2
    assert.strictEqual(
      Number(
        await charityInstance.getNumUnverifiedTransactions(charity.charityId)
      ),
      2,
      'Failed to view number of unverified transactions'
    )
  })
})
