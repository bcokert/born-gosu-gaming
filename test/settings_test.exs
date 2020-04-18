defmodule SettingsTest do
  use ExUnit.Case, async: false
  doctest Settings
  doctest Settings.Server

  test "defaults to daylight savings everywhere" do
    Settings.start_link()

    assert %{
      EDT: -4,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()
  end

  test "remove_output_timezones drops the given timezones and ignores ones that don't exist" do
    Settings.start_link()

    assert %{
      EDT: -4,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.remove_output_timezones([:CEST, :KST])
    assert %{
      EDT: -4,
    } == Settings.get_output_timezones()

    assert :ok == Settings.remove_output_timezones([:APD])
    assert %{
      EDT: -4,
    } == Settings.get_output_timezones()

    assert :ok == Settings.remove_output_timezones([:OREASFD, :EDT])
    assert %{} == Settings.get_output_timezones()
  end

  test "set_daylight_savings only affects the given region and savings value" do
    Settings.start_link()

    assert %{
      EDT: -4,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.set_daylight_savings(false, :na)
    assert %{
      EST: -5,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.set_daylight_savings(true, :na)
    assert %{
      EDT: -4,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.set_daylight_savings(false, :eu)
    assert %{
      EDT: -4,
      CET: 1,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.set_daylight_savings(true, :eu)
    assert %{
      EDT: -4,
      CEST: 2,
      KST: 9,
    } == Settings.get_output_timezones()

    assert :ok == Settings.remove_output_timezones([:CEST, :KST, :EDT])
    assert %{} == Settings.get_output_timezones()

    assert :ok == Settings.set_daylight_savings(false, :eu)
    assert :ok == Settings.set_daylight_savings(true, :na)
    assert %{
      EDT: -4,
      CET: 1,
    } == Settings.get_output_timezones()
  end
end
