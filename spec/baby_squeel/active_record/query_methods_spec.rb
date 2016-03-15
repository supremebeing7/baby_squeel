require 'spec_helper'

describe BabySqueel::ActiveRecord::QueryMethods do
  describe '#joining' do
    it 'can join a relationship with an explicit join' do
      relation = Post.joining {
        author.on(author_id == author.id)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "posts"."author_id" = "authors"."id"
      EOSQL
    end

    it 'can join a relationship with an alias' do
      relation = Post.joining {
        author.alias('a').on(author_id == author.id)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" "a" ON "posts"."author_id" = "authors"."id"
      EOSQL
    end

    it 'can join a relationship with complex conditions' do
      relation = Post.joining {
        author.on(
          (author.id == author_id) & (author.id != 5) | (author.name == nil)
        )
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON ("authors"."id" = "posts"."author_id"
          AND "authors"."id" != 5 OR "authors"."name" IS NULL)
      EOSQL
    end

    it 'can perform an outer join' do
      relation = Post.joining {
        author.outer.on(author_id == author.id)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        LEFT OUTER JOIN "authors" ON "posts"."author_id" = "authors"."id"
      EOSQL
    end

    it 'provides an inner join when explicitly declared' do
      relation = Post.joining {
        author.inner.on(author_id == author.id)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "posts"."author_id" = "authors"."id"
      EOSQL
    end

    it 'can join activerecord associations implicitly' do
      pending 'Not yet implmented'
      relation = Post.joining { author }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "posts"."author_id" = "authors"."id"
      EOSQL
    end
  end

  describe '#selecting' do
    it 'selects using arel' do
      relation = Post.selecting { [id, title] }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts"."id", "posts"."title"
        FROM "posts"
      EOSQL
    end

    it 'selects associations' do
      relation = Post.joins(:author).selecting {
        [id, author.id]
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts"."id", "authors"."id"
        FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
      EOSQL
    end

    it 'selects aggregates' do
      relation = Post.selecting { id.count }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT COUNT("posts"."id")
        FROM "posts"
      EOSQL
    end

    it 'selects using functions' do
      relation = Post.joins(:author).selecting {
        coalesce(id, author.id)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT coalesce("posts"."id", "authors"."id")
        FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
      EOSQL
    end

    it 'selects using operations' do
      relation = Post.joins(:author).selecting {
        author.id - id
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT ("authors"."id" - "posts"."id")
        FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
      EOSQL
    end
  end

  describe '#ordering' do
    it 'orders using arel' do
      relation = Post.ordering { title.desc }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        ORDER BY "posts"."title" DESC
      EOSQL
    end

    it 'orders using multiple arel columns' do
      relation = Post.ordering {
        [title.desc, published_at.asc]
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        ORDER BY "posts"."title" DESC, "posts"."published_at" ASC
      EOSQL
    end

    it 'orders on an aggregates' do
      relation = Post.group('"posts"."id"').ordering {
        id.count.desc
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        GROUP BY "posts"."id"
        ORDER BY COUNT("posts"."id") DESC
      EOSQL
    end

    it 'orders using functions' do
      relation = Post.joins(:author).ordering {
        coalesce(id, author.id).desc
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".*
        FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        ORDER BY coalesce("posts"."id", "authors"."id") DESC
      EOSQL
    end

    it 'orders using operations' do
      relation = Post.joins(:author).ordering {
        (author.id - id).desc
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".*
        FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        ORDER BY ("authors"."id" - "posts"."id") DESC
      EOSQL
    end
  end
end
