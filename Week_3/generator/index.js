const { faker } = require('@faker-js/faker');
const { MongoClient } = require('mongodb');


async function main() {

    const uri = "mongodb://localhost:27017"
    const client = new MongoClient(uri);
  
    try {
      // Connect to the MongoDB cluster
      await client.connect();
  
      const db = client.db("sample")
      // Make the appropriate DB calls
      await loadDelivery(db);
      await loadTracking(db);
      await loadPayments(db);
  
    } finally {
      // Close the connection to the MongoDB cluster
      await client.close();
    }
  }
  
  main().catch(console.error);


async function loadTracking(db) {
    const collection = db.collection("tracking")

    let references = []
    for (let i=0; i < 100; i++) {
      console.log(`Loading data for tracking`);
      let doc = {
        date: faker.date.recent().toISOString().split('T')[0],
        time: faker.date.recent().toISOString().split('T')[1].split('.')[0],
        location: faker.address.city() + ', ' + faker.address.country(),
        gpsLocation: {
          lat: faker.address.latitude(),
          long: faker.address.longitude()
        },
        activity: faker.helpers.arrayElement([
          'origin scan', 'departure scan', 'export scan', 'customs entry',
          'customs exit', 'import scan', 'destination scan', 'out on delivery',
          'delivered', 'held'
        ]),
        internalActivity: faker.datatype.boolean()
      };
     await collection.insertOne(doc)
    }
  }
async function loadPayments(db) {
    const collection = db.collection("payments")

    let references = []
    for (let i=0; i < 100; i++) {
      console.log(`Loading data for payments`);
      let doc = generatePaymentDetails()
     await collection.insertOne(doc)
    }
  }
  
 

async function loadDelivery(db) {
    const collection = db.collection("delivery")

    let references = []
    for (let i=0; i < 100; i++) {
      console.log(`Loading data for delivery`);
      let doc = {
        trackingNumber: '1Z' + faker.string.hexadecimal({ length: 12, prefix: '' }).toUpperCase(),
        packageRFID: faker.string.uuid(),
        status: faker.helpers.arrayElement(['Received', 'AtOrigin', 'InCustoms', 'InTransit', 'AtDestinationWarehouse', 'OutOnDelivery', 'Delivered', 'Exception', 'Returned']),
        scheduledDelivery: faker.date.future().toISOString(),
        shippedFrom: {
          country: faker.address.country(),
          state: faker.address.state(),
          city: faker.address.city(),
          postcode: faker.address.zipCode(),
          street: faker.address.streetAddress(),
          apartmentSuite: faker.datatype.number({ min: 1, max: 1000 }).toString(),
          department: faker.helpers.arrayElement([null, 'Sales', 'Support', 'HR', 'Finance'])
        },
        shippedByEmail: faker.datatype.boolean() ? faker.internet.email() : null,
        shipmentReference: faker.datatype.boolean() ? faker.lorem.words(5) : null,
        shippedTo: {
          country: faker.address.country(),
          state: faker.address.state(),
          city: faker.address.city(),
          postcode: faker.address.zipCode(),
          street: faker.address.streetAddress(),
          apartmentSuite: faker.datatype.number({ min: 1, max: 1000 }).toString(),
          department: faker.helpers.arrayElement([null, 'Sales', 'Support', 'HR', 'Finance'])
        },
        shippedToEmail: faker.datatype.boolean() ? faker.internet.email() : null,
        shippedOrBilledOn: faker.date.future().toISOString(),
        serviceType: faker.helpers.arrayElement(['Express plus', 'Express', 'Express saver', 'Standard']),
        weight: faker.datatype.float({ min: 0.1, max: 100 }).toFixed(2),
        dimensions: {
          length: faker.datatype.number({ min: 1, max: 200 }),
          width: faker.datatype.number({ min: 1, max: 200 }),
          height: faker.datatype.number({ min: 1, max: 200 })
        },
        oversized: faker.datatype.boolean(),
        declaredValue: faker.datatype.boolean() ? faker.datatype.float({ min: 10, max: 10000 }).toFixed(2) : null,
        multiplePackages: faker.datatype.number({ min: 1, max: 10 }),
        additionalFeatures: {
          carbonNeutral: faker.datatype.boolean(),
          saturdayDelivery: faker.datatype.boolean(),
          noThirdPartyDelivery: faker.datatype.boolean(),
          additionalInsurance: faker.datatype.boolean()
        },
        vatNumber: faker.string.alphanumeric({ length: 12, casing: 'upper' })
      };
     await collection.insertOne(doc)
    }
  }
  function generateBillingAddress() {
    return {
      country: faker.address.country(),
      state: faker.address.state(),
      city: faker.address.city(),
      postcode: faker.address.zipCode(),
      street: faker.address.streetAddress(),
      apartmentSuite: faker.datatype.number({ min: 1, max: 1000 }).toString(),
      department: faker.helpers.arrayElement([null, 'Sales', 'Support', 'HR', 'Finance'])
    };
  }
  
  function generatePaymentDetails() {
    const paymentMethod = faker.helpers.arrayElement(['Paypal', 'Payment card', 'Cash']);
    let paymentDetails = {
      trackingNumber: faker.string.hexadecimal({ length: 14, prefix: '' }).toUpperCase(),
      paymentMethod: paymentMethod
    };
  
    if (paymentMethod === 'Payment card') {
      paymentDetails.cardType = faker.helpers.arrayElement(['Visa', 'MasterCard', 'Amex']);
      paymentDetails.cardNumber = faker.finance.creditCardNumber();
      paymentDetails.expirationMonth = faker.date.future().getMonth() + 1;
      paymentDetails.expirationYear = faker.date.future().getFullYear();
      paymentDetails.cvv = faker.finance.creditCardCVV();
      paymentDetails.billingAddress = generateBillingAddress();
    } else if (paymentMethod === 'Paypal') {
      paymentDetails.paypalOperationHash = faker.datatype.uuid();
    } else if (paymentMethod === 'Cash') {
      paymentDetails.logisticsZeroAccessPoint = {
        id: faker.datatype.number({ min: 1000000, max: 9999999 }).toString(),
        address: faker.address.streetAddress(),
        postcode: faker.address.zipCode(),
        town: faker.address.city(),
        city: faker.address.city(),
        country: faker.address.country(),
        vatId: faker.random.alphaNumeric(12).toUpperCase(),
        customsBrokerId: faker.datatype.boolean() ? faker.random.alphaNumeric(8).toUpperCase() : null,
        promoCode: faker.datatype.boolean() ? faker.random.alphaNumeric(10).toUpperCase() : null
      };
    }
  
    return paymentDetails;
  }