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

  const donor = {
    donorAddr: accounts[2]
  }

  const projectId = 0
  const project = {
    title: 'Project 1',
    description: 'Give Leonard Some Food',
    targetAmount: 100,
    charityId: 0,
    charityAddr: charity.owner,
    donorAddr: donor.donorAddr
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
    let verifiedDonor = await donorInstance.verifyDonor(donor.donorAddr, {
      from: accounts[0]
    })

    // donor that is created has an ID of 0
    assert.ok(await donorInstance.isValidDonor(donor.donorAddr))

    truffleAssert.eventEmitted(
      verifiedDonor,
      'donorVerified',
      (ev) => ev.donor == accounts[2]
    )
  })

  it('List Project', async () => {
    let listProject = await projectMarketInstance.listProject(
      project.charityId,
      project.title,
      project.description,
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
      listProject,
      'projectListed',
      (ev) => ev.charityId == project.charityId
    )
  })

  it('Unlist Project', async () => {
    let unlistProject = await projectMarketInstance.unlistProject(
      project.charityId,
      projectId,
      {
        from: accounts[1]
      }
    )
    assert.ok(!(await projectMarketInstance.isProjectActive(projectId)))

    // only owning charity can unlist project
    await truffleAssert.reverts(
      projectMarketInstance.unlistProject(project.charityId, projectId, {
        from: accounts[2]
      }),
      'Only owning charity can perform this action!'
    )

    truffleAssert.eventEmitted(
      unlistProject,
      'projectClosed',
      (ev) => ev.charityId == project.charityId && ev.projectId == projectId
    )
  })

  it('View all project listings', async () => {
    let allProjects = await projectMarketInstance.getAllProjectListings()
    console.log('allProjects', allProjects)
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
    await projectMarketInstance.relistProject(project.charityId, projectId, {
      from: accounts[1]
    })
    await donorInstance.getTokens({
      from: donor.donorAddr,
      value: oneEth
    })
    await charityTokenInstance.approveTokenSpending(donor.donorAddr, 10)
    let donateToProject = await projectMarketInstance.donateToProject(
      projectId,
      10,
      { from: donor.donorAddr }
    )
    truffleAssert.eventEmitted(
      donateToProject,
      'donationMade',
      (ev) => ev.projectId == projectId && ev.donor == donor.donorAddr
    )
    let balanceDonor = await donorInstance.checkTokenBalance({
      from: donor.donorAddr
    })
    assert.strictEqual(
      balanceDonor.toNumber(),
      90,
      'Error donating to project!'
    )
  })
})
