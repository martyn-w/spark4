# frozen_string_literal: true

namespace :spark do
  desc 'Synchronise Spark with Symplectic Elements'
  task sync: :environment do
    puts "Synchronising with Symplectic Elements..."
    Buffer::Runner.new(:sync).run
    puts "All done"
  end
end