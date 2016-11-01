unit TestRedisMQ;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework, RedisMQ, Redis.Commons, Redis.Client, Redis.NetLib.Indy, System.SysUtils;

type
  // Test methods for class TRedisMQ

  TestTRedisMQ = class(TTestCase)
  strict private
    FRedisMQ1, FRedisMQ2: TRedisMQ;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSubscribe;
    procedure TestEmptyTopicQueue;
    procedure TestLotOfMessages;
    procedure TestManualAckMode;
    procedure TestAutoAckMode;
    // procedure TestMultipleBlockingConsume;
    procedure TestInvalidTopicQueue;
    procedure TestUnsubscribe;
    procedure TestDecorateTopicNameForUser;
    procedure TestDecorateProcessingTopicNameForUser;
  end;

implementation

procedure TestTRedisMQ.SetUp;
begin
  FRedisMQ1 := TRedisMQ.Create(NewRedisClient('localhost'), '12345');
  FRedisMQ2 := TRedisMQ.Create(NewRedisClient('localhost'), '67890');
end;

procedure TestTRedisMQ.TearDown;
begin
  FRedisMQ1.Free;
  FRedisMQ2.Free;
end;

procedure TestTRedisMQ.TestAutoAckMode;
var
  lValue, lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1');

  FRedisMQ2.PublishToTopic('topic1', 'msg1');
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckFalse(FRedisMQ1.Ack('topic1', lMessageID));

  FRedisMQ2.PublishToTopic('topic1', 'msg1');
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID, 1, TRMQAckMode.AutoAck));
  CheckFalse(FRedisMQ1.Ack('topic1', lValue));
end;

procedure TestTRedisMQ.TestDecorateProcessingTopicNameForUser;
begin
  CheckEquals('topic1', FRedisMQ1.UnDecorateProcessingTopicNameWithClientID
    (FRedisMQ1.DecorateProcessingTopicNameWithClientID('topic1')));
  CheckEquals('', FRedisMQ1.UnDecorateProcessingTopicNameWithClientID
    (FRedisMQ1.DecorateProcessingTopicNameWithClientID('')));
end;

procedure TestTRedisMQ.TestDecorateTopicNameForUser;
begin
  CheckEquals('topic1', FRedisMQ1.UnDecorateTopicNameWithClientID
    (FRedisMQ1.DecorateTopicNameWithClientID('topic1')));
  CheckEquals('', FRedisMQ1.UnDecorateTopicNameWithClientID
    (FRedisMQ1.DecorateTopicNameWithClientID('')));
end;

procedure TestTRedisMQ.TestEmptyTopicQueue;
var
  lValue: string;
  lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1');

  FRedisMQ1.PublishToTopic('topic1', 'msg1');

  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('msg1', lValue);
  CheckFalse(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('', lValue);
end;

procedure TestTRedisMQ.TestInvalidTopicQueue;
var
  lValue, lMessageID: string;
begin
  CheckFalse(FRedisMQ1.ConsumeTopic('notvalid', lValue, lMessageID));
  CheckEquals('', lValue);
end;

procedure TestTRedisMQ.TestLotOfMessages;
var
  lValue: string;
  I: Integer;
  lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1');

  for I := 1 to 200 do
  begin
    FRedisMQ2.PublishToTopic('topic1', 'msg' + I.ToString);
  end;

  for I := 1 to 200 do
  begin
    CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID, TRMQAckMode.ManualAck));
    CheckTrue(FRedisMQ1.Ack('topic1', lMessageID));
    CheckEquals('msg' + I.ToString, lValue);
  end;
  CheckFalse(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('', lValue);
end;

procedure TestTRedisMQ.TestManualAckMode;
var
  lValue: string;
  lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1');

  FRedisMQ2.PublishToTopic('topic1', 'msg1');
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID, TRMQAckMode.ManualAck));
  CheckNotEquals('', lMessageID);
  CheckTrue(FRedisMQ1.Ack('topic1', lMessageID));
  CheckFalse(FRedisMQ1.Ack('topic1', lMessageID));

  FRedisMQ2.PublishToTopic('topic1', 'msg1');
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID, 1, TRMQAckMode.ManualAck));
  CheckNotEquals('', lMessageID);
  CheckTrue(FRedisMQ1.Ack('topic1', lMessageID));
  CheckFalse(FRedisMQ1.Ack('topic1', lMessageID));

end;

// procedure TestTRedisMQ.TestMultipleBlockingConsume;
// var
// Values: TArray<String>;
// lTopicPair: TRMQTopicPair;
// begin
// FRedisMQ1.SubscribeTopic('topic1');
// FRedisMQ1.SubscribeTopic('topic2');
//
// FRedisMQ2.SubscribeTopic('topic2');
//
// FRedisMQ1.PublishToTopic('topic2', 'msgfromtopic2');
// FRedisMQ2.PublishToTopic('topic1', 'msgfromtopic1');
// FRedisMQ2.PublishToTopic('topic2', 'msgfromtopic2');
//
// CheckTrue(FRedisMQ2.ConsumeTopics(['topic2'], lTopicPair, 2));
// CheckEquals('msgfromtopic2', lTopicPair.Value);
//
// CheckTrue(FRedisMQ1.ConsumeTopics(['topic1', 'topic2'], lTopicPair, 2));
// CheckEquals('topic1', lTopicPair.Topic);
// CheckEquals('msgfromtopic1', lTopicPair.Value);
//
// CheckTrue(FRedisMQ1.ConsumeTopics(['topic1', 'topic2'], lTopicPair, 2));
// CheckEquals('topic2', lTopicPair.Topic);
// CheckEquals('msgfromtopic2', lTopicPair.Value);
//
// end;

procedure TestTRedisMQ.TestSubscribe;
var
  lValue: string;
  lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1');
  FRedisMQ2.SubscribeTopic('topic1');

  // empty queues
  while FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID) do
  begin
    FRedisMQ1.Ack('topic1', lMessageID);
  end;
  while FRedisMQ2.ConsumeTopic('topic1', lValue, lMessageID) do
  begin
    FRedisMQ2.Ack('topic1', lMessageID);
  end;
  // end - empty queues

  FRedisMQ1.PublishToTopic('topic1', 'msg1');
  FRedisMQ2.PublishToTopic('topic1', 'msg2');

  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('msg1', lValue);
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('msg2', lValue);

  CheckTrue(FRedisMQ2.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('msg1', lValue);
  CheckTrue(FRedisMQ2.ConsumeTopic('topic1', lValue, lMessageID));
  CheckEquals('msg2', lValue);

end;

procedure TestTRedisMQ.TestUnsubscribe;
var
  lValue: string;
  lMessageID: string;
begin
  FRedisMQ1.SubscribeTopic('topic1000');
  FRedisMQ1.PublishToTopic('topic1000', 'hello world');
  CheckTrue(FRedisMQ1.ConsumeTopic('topic1000', lValue, lMessageID));
  CheckEquals('hello world', lValue);
  FRedisMQ1.UnsubscribeTopic('topic1000');
  FRedisMQ1.PublishToTopic('topic1000', 'hello world');
  CheckFalse(FRedisMQ1.ConsumeTopic('topic1000', lValue, lMessageID));
  CheckEquals('', lValue);
end;

initialization

// Register any test cases with the test runner
RegisterTest(TestTRedisMQ.Suite);

end.