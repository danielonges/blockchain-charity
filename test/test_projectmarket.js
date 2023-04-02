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

  const charity = {
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
    // donor that is created has an ID of 0
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
        'Project 2',
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
    let allProjects = await projectMarketInstance.getAllActiveProjectListings()
    const projectToCheck = allProjects[0]
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
    assert.strictEqual(
      balanceDonor.toNumber(),
      50,
      'Error donating to project!'
    )
  })

  it('Upload proof of donation', async () => {
    let proofUpload = await projectMarketInstance.verifyProofOfUsage(
      projectId,
      100
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
  })

  it('View all donations by project', async () => {
    let donationsByProject = await projectMarketInstance.getDonationsByProject(
      projectId
    )
    console.log('donationsByProject', donationsByProject)
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
    console.log('donationsByDonor', donationsByDonor)
    assert.strictEqual(
      donationsByDonor.length,
      1,
      'Failed to view all donations by donor'
    )
  })
})
