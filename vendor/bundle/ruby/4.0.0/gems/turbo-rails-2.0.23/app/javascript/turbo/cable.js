let consumer

export async function getConsumer() {
  return consumer || setConsumer(createConsumer().then(setConsumer))
}

export function setConsumer(newConsumer) {
  return consumer = newConsumer
}

export async function createConsumer() {
  const { createConsumer } = await import(/* webpackChunkName: "actioncable" */ "@rails/actioncable/src")
  return createConsumer()
}

export async function subscribeTo(channel, mixin) {
  const { subscriptions } = await getConsumer()
  return subscriptions.create(channel, mixin)
}
