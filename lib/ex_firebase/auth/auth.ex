defmodule ExFirebase.Auth do
  @moduledoc """
  Firebase authentication interface
  """

  alias ExFirebase.Error

  alias ExFirebase.Auth.{
    AccessTokenManager,
    API,
    Certificate,
    JWT,
    PublicKeyManager,
    TokenVerifier
  }

  @api Application.get_env(:ex_firebase, :auth_api) || API

  @doc """
  Returns a cached access token

  ## Examples

      iex> ExFirebase.Auth.access_token()
      {:ok, "1/8xbJqaOZXSUZbHLl5EOtu1pxz3fmmetKx9W8CV4t79M"}
  """
  @spec access_token :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate access_token, to: AccessTokenManager, as: :get_token

  @doc """
  Makes an HTTP request for an OAuth2 access token using a service account's credentials

  ## Examples

      iex> ExFirebase.Auth.get_access_token()
      {:ok,
       %HTTPoison.Response{
         body: %{
           "access_token" => "1/8xbJqaOZXSUZbHLl5EOtu1pxz3fmmetKx9W8CV4t79M",
           "expires_in" => 3600,
           "token_type" => "Bearer"
         },
         ...
         status_code: 200
       }}
  """
  @spec get_access_token ::
          {:ok, HTTPoison.Response.t()}
          | {:error, HTTPoison.Error.t()}
          | {:error, Error.t()}
  def get_access_token do
    with %Certificate{} = certificate <- Certificate.new(),
         {:ok, jwt} <- JWT.from_certificate(certificate) do
      @api.get_access_token(jwt)
    end
  end

  def get_custom_token(user_id) do
    with %Certificate{} = certificate <- Certificate.new(),
         {:ok, jwt} <- JWT.from_certificate(certificate, user_id) do
      @api.get_access_token(jwt)
    end
  end

  @doc """
  Verifies the claims and signature of a Firebase Auth ID token

  ## Examples

      iex> ExFirebase.Auth.verify_token("eyJhbGciOiJS...")
      {:ok,
       %JOSE.JWT{
         fields: %{
           "aud" => "project-id",
           "auth_time" => 1540314428,
           "exp" => 1540318028,
           "firebase" => %{
             "identities" => %{"phone" => ["+16505553434"]},
             "sign_in_provider" => "phone"
           },
           "iat" => 1540314428,
           "iss" => "https://securetoken.google.com/project-id",
           "phone_number" => "+16505553434",
           "sub" => "O5dHhHaWzsgUdNo6jIeTrWykPVd2",
           "user_id" => "O5dHhHaWzsgUdNo6jIeTrWykPVd2"
         }
       }}
  """
  @spec verify_token(String.t()) :: {:ok, JOSE.JWT.t()} | {:error, Error.t()}
  defdelegate verify_token(token), to: TokenVerifier, as: :verify

  @doc """
  Returns cached public keys
  """
  @spec public_keys :: %{String.t() => String.t()}
  defdelegate public_keys, to: PublicKeyManager, as: :get_keys

  @doc """
  Makes an HTTP request to get Google's public keys, whose private keys
  are used to sign Firebase Auth ID tokens
  """
  @spec get_public_keys :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  defdelegate get_public_keys, to: @api, as: :get_public_keys

  @doc """
  Returns a cached public key by id
  """
  @spec get_public_key(String.t()) :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate get_public_key(key_id), to: PublicKeyManager, as: :get_key
end
