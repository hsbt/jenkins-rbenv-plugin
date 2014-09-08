#!/usr/bin/env ruby

require "rbenv/errors"
require 'fileutils'

module Rbenv
  module Semaphore
    DEFAULT_ACQUIRE_MAX = 100
    DEFAULT_ACQUIRE_WAIT = 10
    DEFAULT_RELEASE_MAX = 100
    DEFAULT_RELEASE_WAIT = 10

    def synchronize(dir, workspace, options={})
      begin
        acquire_lock(dir, workspace, options)
        yield
      ensure
        release_lock(dir, workspace, options)
      end
    end

    def acquire_lock(dir, workspace, options={})
      max = options.fetch(:acquire_max, DEFAULT_ACQUIRE_MAX)
      wait = options.fetch(:acquire_wait, DEFAULT_ACQUIRE_WAIT)
      max.times do
        if test("mkdir #{dir.shellescape}")
          FileUtils.touch("#{workspace}/.rbenv_hold_lock")
          return true
        else
          sleep(wait)
        end
      end
      raise(LockError.new("could not acquire lock in #{max * wait} seconds."))
    end

    def release_lock(dir, workspace, options={})
      if File.file?("#{workspace}/.rbenv_hold_lock")
        test("rm -rf #{dir.shellescape}")
      else
        raise(LockError.new("Lock is owned by this build but was unable to release"))
      end
    end
  end
end
