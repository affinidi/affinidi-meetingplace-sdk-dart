//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'date_serializer.dart';
import 'model/date.dart';

import 'model/accept_offer_group_input.dart';
import 'model/accept_offer_group_ok.dart';
import 'model/accept_offer_input.dart';
import 'model/accept_offer_ok.dart';
import 'model/accept_offer_to_connect404_response.dart';
import 'model/admin_deregister_offer_input.dart';
import 'model/admin_deregister_offer_ok.dart';
import 'model/check_offer_phrase_input.dart';
import 'model/check_offer_phrase_ok.dart';
import 'model/cors_register_device_ok.dart';
import 'model/create_oob_input.dart';
import 'model/create_oob_ok.dart';
import 'model/delete_pending_notifications_input.dart';
import 'model/delete_pending_notifications_ok.dart';
import 'model/delete_pending_notifications_ok_notifications_inner.dart';
import 'model/deregister_notification_input.dart';
import 'model/deregister_offer_input.dart';
import 'model/deregister_offer_ok.dart';
import 'model/did_authenticate.dart';
import 'model/did_authenticate_ok.dart';
import 'model/did_challenge.dart';
import 'model/did_challenge_ok.dart';
import 'model/expired_acceptance_error.dart';
import 'model/finalise_offer_acceptance404_response.dart';
import 'model/finalise_offer_input.dart';
import 'model/finalise_offer_ok.dart';
import 'model/get_oob_not_found_error.dart';
import 'model/get_oob_ok.dart';
import 'model/get_pending_notifications_input.dart';
import 'model/get_pending_notifications_ok.dart';
import 'model/get_pending_notifications_ok_notifications_inner.dart';
import 'model/group_add_member_input.dart';
import 'model/group_add_member_ok.dart';
import 'model/group_delete_input.dart';
import 'model/group_delete_ok.dart';
import 'model/group_deregister_member_input.dart';
import 'model/group_member_deregister_ok.dart';
import 'model/group_send_message.dart';
import 'model/group_send_message_ok.dart';
import 'model/invalid_acceptance_error.dart';
import 'model/invalid_offer_error.dart';
import 'model/not_found_error.dart';
import 'model/not_found_error_details_inner.dart';
import 'model/notify_accept_offer_group_input.dart';
import 'model/notify_accept_offer_group_ok.dart';
import 'model/notify_accept_offer_input.dart';
import 'model/notify_accept_offer_ok.dart';
import 'model/notify_channel_input.dart';
import 'model/notify_channel_ok.dart';
import 'model/notify_outreach_input.dart';
import 'model/notify_outreach_ok.dart';
import 'model/offer_expired_error.dart';
import 'model/offer_limit_exceeded_error.dart';
import 'model/offer_phrase_in_use_error.dart';
import 'model/offer_unprocessable_entity_error.dart';
import 'model/query_offer404_response.dart';
import 'model/query_offer_input.dart';
import 'model/query_offer_ok.dart';
import 'model/register_device_input.dart';
import 'model/register_device_ok.dart';
import 'model/register_notification_input.dart';
import 'model/register_notification_ok.dart';
import 'model/register_offer_group_input.dart';
import 'model/register_offer_group_ok.dart';
import 'model/register_offer_input.dart';
import 'model/register_offer_ok.dart';
import 'model/update_offers_score_error.dart';
import 'model/update_offers_score_input.dart';
import 'model/update_offers_score_ok.dart';
import 'model/update_offers_score_ok_failed_offers_inner.dart';

part 'serializers.g.dart';

@SerializersFor([
  AcceptOfferGroupInput,
  AcceptOfferGroupOK,
  AcceptOfferInput,
  AcceptOfferOK,
  AcceptOfferToConnect404Response,
  AdminDeregisterOfferInput,
  AdminDeregisterOfferOK,
  CheckOfferPhraseInput,
  CheckOfferPhraseOK,
  CorsRegisterDeviceOK,
  CreateOobInput,
  CreateOobOK,
  DeletePendingNotificationsInput,
  DeletePendingNotificationsOK,
  DeletePendingNotificationsOKNotificationsInner,
  DeregisterNotificationInput,
  DeregisterOfferInput,
  DeregisterOfferOK,
  DidAuthenticate,
  DidAuthenticateOK,
  DidChallenge,
  DidChallengeOK,
  ExpiredAcceptanceError,
  FinaliseOfferAcceptance404Response,
  FinaliseOfferInput,
  FinaliseOfferOK,
  GetOobNotFoundError,
  GetOobOK,
  GetPendingNotificationsInput,
  GetPendingNotificationsOK,
  GetPendingNotificationsOKNotificationsInner,
  GroupAddMemberInput,
  GroupAddMemberOK,
  GroupDeleteInput,
  GroupDeleteOK,
  GroupDeregisterMemberInput,
  GroupMemberDeregisterOK,
  GroupSendMessage,
  GroupSendMessageOK,
  InvalidAcceptanceError,
  InvalidOfferError,
  NotFoundError,
  NotFoundErrorDetailsInner,
  NotifyAcceptOfferGroupInput,
  NotifyAcceptOfferGroupOK,
  NotifyAcceptOfferInput,
  NotifyAcceptOfferOK,
  NotifyChannelInput,
  NotifyChannelOK,
  NotifyOutreachInput,
  NotifyOutreachOK,
  OfferExpiredError,
  OfferLimitExceededError,
  OfferPhraseInUseError,
  OfferUnprocessableEntityError,
  QueryOffer404Response,
  QueryOfferInput,
  QueryOfferOK,
  RegisterDeviceInput,
  RegisterDeviceOK,
  RegisterNotificationInput,
  RegisterNotificationOK,
  RegisterOfferGroupInput,
  RegisterOfferGroupOK,
  RegisterOfferInput,
  RegisterOfferOK,
  UpdateOffersScoreError,
  UpdateOffersScoreInput,
  UpdateOffersScoreOK,
  UpdateOffersScoreOKFailedOffersInner,
])
Serializers serializers =
    (_$serializers.toBuilder()
          ..add(const OneOfSerializer())
          ..add(const AnyOfSerializer())
          ..add(const DateSerializer())
          ..add(Iso8601DateTimeSerializer()))
        .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
