# frozen_string_literal: true

module ReedSolomon
  # Finite field arithmetic.
  # Largely based on https://en.wikiversity.org/wiki/Reed–Solomon_codes_for_coders#Finite_field_arithmetic
  # and https://github.com/Backblaze/JavaReedSolomon
  class GF
    BASE = 2
    EXP = 8
    PRIM = 0x1d
    FIELD_SIZE = BASE**EXP
    MOD = FIELD_SIZE - 1

    def initialize(prim: PRIM, lut: false)
      @gf_log = log_table(prim: prim)
      @gf_exp = exp_table(prim: prim)

      # in brief experimental testing, I saw ~0 benefit to including the LUT.
      if lut
        @gf_mul = mul_table

        define_singleton_method(:mul) do |v1, v2|
          @gf_mul[v1][v2]
        end
      end
    end

    def add(v1, v2)
      v1 ^ v2
    end

    def sub(v1, v2)
      v1 ^ v2
    end

    def mul(v1, v2)
      if v1 == 0 || v2 == 0
        0
      else
        @gf_exp[@gf_log[v1] + @gf_log[v2]]
      end
    end

    def div(value, divisor)
      if value == 0
        0
      elsif divisor == 0
        raise ZeroDivisionError
      else
        @gf_exp[@gf_log[value] + MOD - @gf_log[divisor]]
      end
    end

    def pow(value, power)
      @gf_exp[(@gf_log[value] * power) % MOD]
    end

    def inv(value)
      @gf_exp[MOD - @gf_log[value]]
    end

    # I have no issue with these methods being called, but they mostly exist solely for
    # set up, so mark them as protected :shrug:
    protected

    # Generate the log table for GF maths
    # see: https://github.com/Backblaze/JavaReedSolomon/blob/0e7f3c84350b416bf1431215929241c6d82f03fe/src/main/java/com/backblaze/erasure/Galois.java#L259
    def log_table(prim: PRIM)
      # Add MSB for field size to handle subtraction
      prim |= FIELD_SIZE

      # -1 is invalid and log(0) doesn't exist, so leave that as a non-value
      gf_log = Array.new(FIELD_SIZE, -1)

      x = 1
      # Upper bounds inclusive
      0.upto(FIELD_SIZE - 2) do |i|
        gf_log[x] = i
        x <<= 1
        x ^= prim if x >= FIELD_SIZE
      end

      gf_log
    end

    # Generate the antilog table for GF maths
    # see: https://github.com/Backblaze/JavaReedSolomon/blob/0e7f3c84350b416bf1431215929241c6d82f03fe/src/main/java/com/backblaze/erasure/Galois.java#L281
    def exp_table(prim: PRIM)
      prim |= FIELD_SIZE
      gf_exp = Array.new(FIELD_SIZE - 1, 0)

      x = 1
      0.upto(FIELD_SIZE - 2) do |i|
        gf_exp[i] = x
        x <<= 1
        x ^= prim if x >= FIELD_SIZE
      end
      # Append the table to itself since we always to lookups (mod 255) anyways
      gf_exp + gf_exp
    end

    # Note: requires the exp and log tables to be computed first
    def mul_table
      (0...FIELD_SIZE).map do |v1|
        (0...FIELD_SIZE).map do |v2|
          mul(v1, v2)
        end
      end
    end
  end
end
