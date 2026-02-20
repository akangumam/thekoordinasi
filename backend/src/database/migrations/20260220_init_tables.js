/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema
    .createTable('users', (table) => {
      table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
      table.string('full_name').notNullable();
      table.string('phone').notNullable().unique();
      table.string('motorcycle').nullable();
      table.timestamp('created_at').defaultTo(knex.fn.now());
    })
    .createTable('rides', (table) => {
      table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
      table.string('title').notNullable();
      table.string('code', 6).notNullable().unique();
      table.uuid('leader_id').references('id').inTable('users').onDelete('CASCADE');
      table.enum('status', ['active', 'ended']).defaultTo('active');
      table.timestamp('created_at').defaultTo(knex.fn.now());
      table.timestamp('ended_at').nullable();
    })
    .createTable('ride_participants', (table) => {
      table.increments('id').primary();
      table.uuid('ride_id').references('id').inTable('rides').onDelete('CASCADE');
      table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE');
      table.timestamp('joined_at').defaultTo(knex.fn.now());
      table.unique(['ride_id', 'user_id']); // User can't join same ride twice
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('ride_participants')
    .dropTableIfExists('rides')
    .dropTableIfExists('users');
};
