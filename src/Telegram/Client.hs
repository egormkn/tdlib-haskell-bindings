{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Telegram.Client where

import           Data.Aeson
import qualified Data.Text                     as Text
import           Telegram.Database.API.Authorization
import           Telegram.Database.API.Update
import qualified Telegram.Database.JSON        as TDLib
import           Telegram.Database.JSON         ( Client )

process :: (Update -> Client -> IO ()) -> Client -> IO ()
process handle client = do
  update <- TDLib.receiveEither client :: IO (Either String Update)
  case update of
    Left "NULL"  -> process handle client
    Left error   -> putStrLn error       >> process handle client
    Right update -> handle update client >> process handle client

defaultHandler :: Update -> Client -> IO ()
defaultHandler UpdateAuthorizationState {..} = 
  updateAuthorizationState authorization_state
defaultHandler unhandled =
  const $ putStrLn $ ">>>>> UNHANDLED: \n" ++ show unhandled

updateAuthorizationState :: AuthorizationState -> Client -> IO ()
updateAuthorizationState state client = case state of
  AuthorizationStateClosed ->
    return ()
  AuthorizationStateClosing ->
    return ()
  AuthorizationStateLoggingOut ->
    return ()
  AuthorizationStateReady ->
    return ()
  AuthorizationStateWaitCode isRegistered termsOfService codeInfo -> do
    putStrLn "Please, enter verification code:"
    code <- Text.pack <$> getLine
    checkAuthenticationCode code "" "" client
  AuthorizationStateWaitEncryptionKey isEncrypted ->
    checkDatabaseEncryptionKey "" client
  AuthorizationStateWaitPassword passwordHint hasRecoveryEmailAddress recoveryEmailAddressPattern -> do
    putStrLn "Please, enter password:"
    password <- Text.pack <$> getLine
    checkAuthenticationPassword password client
  AuthorizationStateWaitPhoneNumber -> do
    putStrLn "Please, enter mobile phone number:"
    number <- Text.pack <$> getLine
    setAuthenticationPhoneNumber number False False client
  AuthorizationStateWaitTdlibParameters -> do
    putStrLn "Please, enter Telegram API ID:"
    apiId <- read <$> getLine
    putStrLn "Please, enter Telegram API hash:"
    apiHash <- getLine
    setTdlibParameters defaultTdlibParameters { api_id = apiId, api_hash = apiHash } client

