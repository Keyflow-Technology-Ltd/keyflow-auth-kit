//
//  Events.swift
//  KeyflowEventsKit
//
//  Canonical event taxonomy for the Keyflow ecosystem.
//  DO NOT edit by hand — generated from ../events.json.
//  Keep in lockstep with keyflow-auth/src/lib/events.ts.
//

import Foundation

public enum KeyflowEvent: String, CaseIterable, Sendable {
    // MARK: Session
    case signinSucceeded = "signin_succeeded"
    case signinFailed = "signin_failed"
    case signoutInitiated = "signout_initiated"
    case handoffAccepted = "handoff_accepted"

    // MARK: Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"

    // MARK: FirstValue
    case firstLeadAdded = "first_lead_added"
    case firstListingCreated = "first_listing_created"
    case firstDealCreated = "first_deal_created"
    case firstRenewalInitiated = "first_renewal_initiated"

    // MARK: Hero
    case heroImportCompleted = "hero_import_completed"
    case heroListingPublished = "hero_listing_published"
    case heroRenewalSent = "hero_renewal_sent"

    // MARK: AI
    case aiSuggestionShown = "ai_suggestion_shown"
    case aiSuggestionAccepted = "ai_suggestion_accepted"
    case aiSuggestionRejected = "ai_suggestion_rejected"
    case aiSuggestionAutoAccepted = "ai_suggestion_auto_accepted"
    case aiSuggestionRationaleViewed = "ai_suggestion_rationale_viewed"

    // MARK: Communication
    case connectMessageSent = "connect_message_sent"
    case connectMessageReceived = "connect_message_received"
    case autoReplyDraftShown = "auto_reply_draft_shown"
    case voiceNoteTranscribed = "voice_note_transcribed"

    // MARK: Handoffs
    case leadConvertedToListing = "lead_converted_to_listing"
    case leadConvertedToDealPipeline = "lead_converted_to_deal_pipeline"
    case dealClosedToLease = "deal_closed_to_lease"
    case universalSearchPerformed = "universal_search_performed"

    // MARK: Viral
    case teamInviteSent = "team_invite_sent"
    case teamInviteAccepted = "team_invite_accepted"
    case shareLinkOpened = "share_link_opened"
    case attributionSignup = "attribution_signup"

    // MARK: Signature
    case dealClosed = "deal_closed"
    case listingPublished = "listing_published"
    case renewalCompleted = "renewal_completed"
    case leadAssigned = "lead_assigned"

    // MARK: Documents
    case documentGenerated = "document_generated"
    case documentApprovalRequested = "document_approval_requested"
    case documentApprovalResolved = "document_approval_resolved"

    // MARK: Retention
    case reviewPromptShown = "review_prompt_shown"
    case dailyBriefOpened = "daily_brief_opened"
}

public enum KeyflowProductId: String, Sendable {
    case leadsflow
    case dealsflow
    case leaseflow
    case auth
    case connect
}
