# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      # 会議1つに対する、ある account の権限判定を一箇所に集約する。
      # 機能ロールごとに「何ができるか」を定義し、各 Usecase / Action はここに問い合わせる。
      #
      #   account     : Account エンティティ（admin? を持つ）
      #   participant : その会議の MeetingParticipant（nil = 未参加）
      class MeetingPolicy
        ROLES = %w[facilitator timekeeper secretary presenter].freeze

        def initialize(account:, participant:)
          @account = account
          @participant = participant
        end

        # 閲覧・通常の発言: 参加者全員 + admin（監視）
        def can_view?
          admin? || participant?
        end

        # 会議の開始/終了・議題の進行: 進行（facilitator）
        def can_progress_meeting?
          has_role?("facilitator")
        end

        # タイマーの開始/停止/リセット: タイムキーパー
        def can_control_timer?
          has_role?("timekeeper")
        end

        # 議事録の作成/編集: 書記
        def can_edit_minutes?
          has_role?("secretary")
        end

        # 発表モードの切替・発表中アイデアの制御: 発表
        def can_control_presentation?
          has_role?("presenter")
        end

        # 参加者の追加・機能ロールの付与/はく奪: admin のみ（ローカル管理者が必ず担う）
        def can_manage_roles?
          admin?
        end

        # フロントの表示出し分け用にまとめて返す
        def capabilities
          {
            view: can_view?,
            progress_meeting: can_progress_meeting?,
            control_timer: can_control_timer?,
            edit_minutes: can_edit_minutes?,
            control_presentation: can_control_presentation?,
            manage_roles: can_manage_roles?
          }
        end

        private

        def admin?
          @account.respond_to?(:admin?) && @account.admin?
        end

        def participant?
          !@participant.nil?
        end

        def has_role?(role)
          !@participant.nil? && @participant.role?(role)
        end
      end
    end
  end
end
