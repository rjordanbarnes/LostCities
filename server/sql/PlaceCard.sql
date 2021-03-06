/*

  Contains turn logic to place a card.

  Turns have two parts:
    This file --> 1. Play a card to a score pile or discard pile.
    2. Draw a card from the deck or a discard pile.


  @accountSK
  The user that's making the turn. An AccountSK

  @playedCardSK
  The card they're playing. A CardSK

  @playedCardLocationType
  The type of location the card is being played. Either a ScorePile or a DiscardPile.

  @playedCardLocationSK
  The SK of the location they're playing the card.

*/

--DECLARE @accountSK INT = (SELECT AccountSK FROM Account WHERE Username = 'Jordan');
--DECLARE @playedCardSK INT = '38EF9C76-6772-4692-8B15-EC3293E4F547';
--DECLARE @playedCardLocationType NVARCHAR(200) = '';
--DECLARE @playedCardLocationSK INT = '99A7883B-80C4-4A6E-9E57-9E97A7F85258';

/*

  Computed variables

*/

BEGIN TRANSACTION
BEGIN TRY

  -- Game that the user is in.
  DECLARE @gameSK INT = (SELECT GameSK FROM GameMember WHERE AccountSK = @accountSK);

  -- GameMember associated with user.
  DECLARE @gameMemberSK INT = (SELECT GameMemberSK FROM GameMember WHERE AccountSK = @accountSK);

  -- User's hand
  DECLARE @handSK INT = (SELECT HandSK FROM Hand WHERE PlayerSK = @gameMemberSK AND GameSK = @gameSK);

  /*

    Validations

  */

  -- Inputs must be provided
  IF (@accountSK IS NULL OR @playedCardSK IS NULL OR @playedCardLocationSK IS NULL)
    THROW 50001, 'Unable to place card: user, played card, and played card location must be supplied.', 1;

  -- Played card location type must be valid.
  IF (@playedCardLocationType <> 'ScorePile' AND @playedCardLocationType <> 'DiscardPile')
    THROW 50001, 'Played card location type must be ScorePile or DiscardPile', 1;

  -- User must be in a game.
  IF (@gameSK IS NULL)
    THROW 50001, 'Unable to place card, user isn''t in a game.', 1;

  -- User must be a player.
  IF ((SELECT COUNT(*) FROM GameMember WHERE GameSK = @gameSK AND GameMemberSK = @gameMemberSK AND GameMemberType = 'Player') < 1)
    THROW 50001, 'Unable to place card, user isn''t a player.', 1;

  -- It must be the user's turn.
  IF ((SELECT COUNT(*) FROM GameMember WHERE GameSK = @gameSK AND GameMemberSK = @gameMemberSK AND IsTurn = 1) < 1)
    THROW 50001, 'Unable to place card, it isn''t user''s turn.', 1;

  -- Game must be in gameplay state.
  IF ((SELECT GameState FROM Game WHERE GameSK = @gameSK) != 'Gameplay')
    THROW 50001, 'Unable to place card, game isn''t in gameplay state.', 1;

  -- Supplied card must be in the user's hand.
  IF ((SELECT COUNT(*) FROM HandCard WHERE HandSK = @handSK AND CardSK = @playedCardSK) < 1)
    THROW 50001, 'Unable to place card, card isn''t in user''s hand.', 1;


  /*

    Play Card

  */

  -- If playing card on a score pile.
  IF (@playedCardLocationType = 'ScorePile')
  BEGIN

    -- Score Pile must be the player's own in their own game.
    IF ((SELECT COUNT(*) FROM ScorePile WHERE ScorePileSK = @playedCardLocationSK AND GameSK = @gameSK AND PlayerSK = @gameMemberSK) = 0)
      THROW 50001, 'Selected score pile must be the player''s and be in the player''s game.', 1;

    -- Card color must match ScorePile color
    IF ((SELECT CardColor FROM Card WHERE CardSK = @playedCardSK) != (SELECT ScorePileColor FROM ScorePile WHERE ScorePileSK = @playedCardLocationSK))
      THROW 50001, 'Unable to play card, card color must match score pile color.', 1;

    DECLARE @largestScorePileValue INT = (SELECT TOP 1 CardValue FROM ScorePile
                                          INNER JOIN ScorePileCard ON (ScorePile.ScorePileSK = ScorePileCard.ScorePileSK)
                                          INNER JOIN Card ON (ScorePileCard.CardSK = Card.CardSK)
                                          WHERE ScorePile.ScorePileSK = @playedCardLocationSK
                                          ORDER BY CardValue DESC);

    -- Card must be of greater value than the highest value card in the pile.
    IF (@largestScorePileValue IS NOT NULL AND (@largestScorePileValue > (SELECT CardValue FROM Card WHERE CardSK = @playedCardSK)))
      THROW 50001, 'Unable to play card, card value must be greater than largest card on score pile.', 1;

    -- Play the card into the user's score pile
    INSERT INTO ScorePileCard (CardSK, ScorePileSK)
    VALUES
      (@playedCardSK, @playedCardLocationSK)

    DELETE FROM HandCard
    WHERE CardSK = @playedCardSK AND HandSK = @handSK

  END

  -- If playing card on a discard pile.
  ELSE IF (@playedCardLocationType = 'DiscardPile')
  BEGIN

    -- Score Pile must be in the player's game.
    IF ((SELECT COUNT(*) FROM DiscardPile WHERE DiscardPileSK = @playedCardLocationSK AND GameSK = @gameSK) = 0)
      THROW 50001, 'Selected discard pile must be in the player''s game.', 1;

    -- Card color must match DiscardPile color
    IF ((SELECT CardColor FROM Card WHERE CardSK = @playedCardSK) != (SELECT DiscardPileColor FROM DiscardPile WHERE DiscardPileSK = @playedCardLocationSK))
      THROW 50001, 'Unable to play card, card color must match discard pile color.', 1;

    -- Play the card into the discard pile
    INSERT INTO DiscardPileCard (CardSK, DiscardPileSK)
    VALUES
      (@playedCardSK, @playedCardLocationSK)

    DELETE FROM HandCard
    WHERE CardSK = @playedCardSK AND HandSK = @handSK

  END

  UPDATE Game
  SET TurnState = 'Drawing'
  WHERE GameSK = @gameSK

  SELECT @gameSK AS game
  FROM Account
  WHERE AccountSK = @accountSK

END TRY
BEGIN CATCH
  DECLARE @error int,
          @message varchar(4000),
          @xstate int;

  SELECT
      @error = 50000,
      @message = ERROR_MESSAGE(),
      @xstate = XACT_STATE();

  ROLLBACK TRANSACTION;

  THROW @error, @message, @xstate;

END CATCH

IF @@TRANCOUNT > 0
  COMMIT TRANSACTION;
