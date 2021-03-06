# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Naming::MemoizedInstanceVariableName, :config do
  context 'with default EnforcedStyleForLeadingUnderscores => disallowed' do
    let(:cop_config) do
      { 'EnforcedStyleForLeadingUnderscores' => 'disallowed' }
    end

    context 'when or-assignment-based memoization is used' do
      context 'memoized variable does not match method name' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def x
              @my_var ||= :foo
              ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
            end
          RUBY
        end
      end

      context 'memoized variable does not match class method name' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def self.x
              @my_var ||= :foo
              ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
            end
          RUBY
        end
      end

      context 'memoized variable does not match method name during assignment' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            foo = def x
              @y ||= :foo
              ^^ Memoized variable `@y` does not match method name `x`. Use `@x` instead.
            end
          RUBY
        end
      end

      context 'memoized variable does not match method name for block' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def x
              @y ||= begin
              ^^ Memoized variable `@y` does not match method name `x`. Use `@x` instead.
                :foo
              end
            end
          RUBY
        end
      end

      context 'memoized variable after other code does not match method name' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def foo
              helper_variable = something_we_need_to_calculate_foo
              @bar ||= calculate_expensive_thing(helper_variable)
              ^^^^ Memoized variable `@bar` does not match method name `foo`. Use `@foo` instead.
            end
          RUBY
        end

        it 'registers an offense for a predicate method' do
          expect_offense(<<~RUBY)
            def foo?
              helper_variable = something_we_need_to_calculate_foo
              @bar ||= calculate_expensive_thing(helper_variable)
              ^^^^ Memoized variable `@bar` does not match method name `foo?`. Use `@foo` instead.
            end
          RUBY
        end

        it 'registers an offense for a bang method' do
          expect_offense(<<~RUBY)
            def foo!
              helper_variable = something_we_need_to_calculate_foo
              @bar ||= calculate_expensive_thing(helper_variable)
              ^^^^ Memoized variable `@bar` does not match method name `foo!`. Use `@foo` instead.
            end
          RUBY
        end
      end

      context 'memoized variable matches method name' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def x
              @x ||= :foo
            end
          RUBY
        end

        it 'does not registers an offense when method has leading `_`' do
          expect_no_offenses(<<~RUBY)
            def _foo
              @foo ||= :foo
            end
          RUBY
        end

        it 'does not register an offense with a leading `_` for both names' do
          expect_no_offenses(<<~RUBY)
            def _foo
              @_foo ||= :foo
            end
          RUBY
        end

        context 'memoized variable matches method name during assignment' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              foo = def y
                @y ||= :foo
              end
            RUBY
          end
        end

        context 'memoized variable matches method name for block' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def z
                @z ||= begin
                  :foo
                end
              end
            RUBY
          end
        end

        context 'non-memoized variable does not match method name' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def a
                x ||= :foo
              end
            RUBY
          end
        end

        context 'memoized variable matches predicate method name' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def a?
                @a ||= :foo
              end
            RUBY
          end
        end

        context 'memoized variable matches bang method name' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def a!
                @a ||= :foo
              end
            RUBY
          end
        end

        context 'code follows memoized variable assignment' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def a
                @b ||= :foo
                call_something_else
              end
            RUBY
          end

          context 'memoized variable after other code' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                def foo
                  helper_variable = something_we_need_to_calculate_foo
                  @foo ||= calculate_expensive_thing(helper_variable)
                end
              RUBY
            end
          end

          context 'instance variables in initialize methods' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                def initialize
                  @files_with_offenses ||= {}
                end
              RUBY
            end
          end
        end
      end
    end

    context 'when defined?-based memoization is used' do
      it 'registers an offense when memoized variable does not match method name' do
        expect_offense(<<~RUBY)
          def x
            return @my_var if defined?(@my_var)
                   ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
                                       ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
            @my_var = false
            ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
          end
        RUBY
      end

      it 'registers an offense when memoized variable does not match class method name' do
        expect_offense(<<~RUBY)
          def self.x
            return @my_var if defined?(@my_var)
                   ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
                                       ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
            @my_var = false
            ^^^^^^^ Memoized variable `@my_var` does not match method name `x`. Use `@x` instead.
          end
        RUBY
      end

      context 'memoized variable matches method name' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def x
              return @x if defined?(@x)
              @x = false
            end
          RUBY
        end

        it 'does not register an offense when method has leading `_`' do
          expect_no_offenses(<<~RUBY)
            def _foo
              return @foo if defined?(@foo)
              @foo = false
            end
          RUBY
        end

        it 'does not register an offense with a leading `_` for both names' do
          expect_no_offenses(<<~RUBY)
            def _foo
              return @_foo if defined?(@_foo)
              @_foo = false
            end
          RUBY
        end

        context 'non-memoized variable does not match method name' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def a
                return x if defined?(x)
                x = 1
              end
            RUBY
          end
        end

        it 'does not register an offense when memoized variable matches predicate method name' do
          expect_no_offenses(<<~RUBY)
            def a?
              return @a if defined?(@a)
              @a = false
            end
          RUBY
        end

        it 'does not register an offense when memoized variable matches bang method name' do
          expect_no_offenses(<<~RUBY)
            def a!
              return @a if defined?(@a)
              @a = false
            end
          RUBY
        end
      end

      it 'does not register an offense when some code before defined' do
        expect_no_offenses(<<~RUBY)
          def x
            do_something
            return @x if defined?(@x)
            @x = false
          end
        RUBY
      end

      it 'does not register an offense when some code after assignment' do
        expect_no_offenses(<<~RUBY)
          def x
            return @x if defined?(@x)
            @x = false
            do_something
          end
        RUBY
      end

      it 'does not register an offense when there is no assignment' do
        expect_no_offenses(<<~RUBY)
          def x
            return @x if defined?(@x)
          end
        RUBY
      end
    end
  end

  context 'EnforcedStyleForLeadingUnderscores: required' do
    let(:cop_config) { { 'EnforcedStyleForLeadingUnderscores' => 'required' } }

    context 'when or-assignment-based memoization is used' do
      it 'registers an offense when names match but missing a leading _' do
        expect_offense(<<~RUBY)
          def foo
            @foo ||= :foo
            ^^^^ Memoized variable `@foo` does not start with `_`. Use `@_foo` instead.
          end
        RUBY
      end

      it 'registers an offense when it has leading `_` but names do not match' do
        expect_offense(<<~RUBY)
          def foo
            @_my_var ||= :foo
            ^^^^^^^^ Memoized variable `@_my_var` does not match method name `foo`. Use `@_foo` instead.
          end
        RUBY
      end

      it 'does not register an offense with a leading `_` for both names' do
        expect_no_offenses(<<~RUBY)
          def _foo
            @_foo ||= :foo
          end
        RUBY
      end
    end

    context 'when defined?-based memoization is used' do
      it 'registers an offense when names match but missing a leading _' do
        expect_offense(<<~RUBY)
          def foo
            return @foo if defined?(@foo)
                   ^^^^ Memoized variable `@foo` does not start with `_`. Use `@_foo` instead.
                                    ^^^^ Memoized variable `@foo` does not start with `_`. Use `@_foo` instead.
            @foo = false
            ^^^^ Memoized variable `@foo` does not start with `_`. Use `@_foo` instead.
          end
        RUBY
      end

      it 'registers an offense when it has leading `_` but names do not match' do
        expect_offense(<<~RUBY)
          def foo
            return @_my_var if defined?(@_my_var)
                   ^^^^^^^^ Memoized variable `@_my_var` does not match method name `foo`. Use `@_foo` instead.
                                        ^^^^^^^^ Memoized variable `@_my_var` does not match method name `foo`. Use `@_foo` instead.
            @_my_var = false
            ^^^^^^^^ Memoized variable `@_my_var` does not match method name `foo`. Use `@_foo` instead.
          end
        RUBY
      end

      it 'does not register an offense with a leading `_` for both names' do
        expect_no_offenses(<<~RUBY)
          def _foo
            return @_foo if defined?(@_foo)
            @_foo = false
          end
        RUBY
      end
    end
  end

  context 'EnforcedStyleForLeadingUnderscores: optional' do
    let(:cop_config) { { 'EnforcedStyleForLeadingUnderscores' => 'optional' } }

    context 'when or-assignment-based memoization is used' do
      context 'memoized variable matches method name' do
        it 'does not register an offense with a leading underscore' do
          expect_no_offenses(<<~RUBY)
            def x
              @_x ||= :foo
            end
          RUBY
        end

        it 'does not register an offense without a leading underscore' do
          expect_no_offenses(<<~RUBY)
            def x
              @x ||= :foo
            end
          RUBY
        end

        it 'does not register an offense with a leading `_` for both names' do
          expect_no_offenses(<<~RUBY)
            def _x
              @_x ||= :foo
            end
          RUBY
        end

        it 'does not register an offense with a leading `_` for method name' do
          expect_no_offenses(<<~RUBY)
            def _x
              @x ||= :foo
            end
          RUBY
        end
      end

      context 'when defined?-based memoization is used' do
        context 'memoized variable matches method name' do
          it 'does not register an offense with a leading underscore' do
            expect_no_offenses(<<~RUBY)
              def x
                return @_x if defined?(@_x)
                @_x = false
              end
            RUBY
          end

          it 'does not register an offense without a leading underscore' do
            expect_no_offenses(<<~RUBY)
              def x
                return @x if defined?(@x)
                @x = false
              end
            RUBY
          end

          it 'does not register an offense with a leading `_` for both names' do
            expect_no_offenses(<<~RUBY)
              def _x
                return @_x if defined?(@_x)
                @_x = false
              end
            RUBY
          end

          it 'does not register an offense with a leading `_` for method name' do
            expect_no_offenses(<<~RUBY)
              def _x
                return @x if defined?(@x)
                @x = false
              end
            RUBY
          end
        end
      end
    end
  end
end
