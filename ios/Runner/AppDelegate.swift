import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IosNativeDockPlugin") {
      IosNativeDockPlugin.register(with: registrar)
    }
  }
}

private enum IosNativeDockTab: Int, CaseIterable {
  case checklist
  case overview
  case pets
  case me

  var channelName: String {
    switch self {
    case .checklist:
      return "checklist"
    case .overview:
      return "overview"
    case .pets:
      return "pets"
    case .me:
      return "me"
    }
  }

  var title: String {
    switch self {
    case .checklist:
      return "清单"
    case .overview:
      return "总览"
    case .pets:
      return "爱宠"
    case .me:
      return "我的"
    }
  }

  var iconName: String {
    switch self {
    case .checklist:
      return "checklist"
    case .overview:
      return "sparkles"
    case .pets:
      return "pawprint.fill"
    case .me:
      return "person.fill"
    }
  }
}

final class IosNativeDockPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let factory = IosNativeDockViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "pet_care_harmony/ios_native_dock")
  }
}

final class IosNativeDockViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    IosNativeDockPlatformView(
      frame: frame,
      viewId: viewId,
      args: args as? [String: Any],
      messenger: messenger
    )
  }
}

final class IosNativeDockPlatformView: NSObject, FlutterPlatformView, UITabBarControllerDelegate {
  private let rootView = UIView()
  private let tabBarController = UITabBarController()
  private let channel: FlutterMethodChannel
  private var controllersByTab: [IosNativeDockTab: UIViewController] = [:]
  private var addPlaceholderController: UIViewController?
  private var isSyncingSelection = false
  private let interfaceStyle: UIUserInterfaceStyle
  private let centerSymbolSize: CGFloat
  private let centerSymbolCanvasOffset: CGFloat

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    let brightness = (args?["brightness"] as? String) ?? "light"
    centerSymbolSize = CGFloat((args?["centerSymbolSize"] as? Double) ?? 42)
    centerSymbolCanvasOffset = CGFloat((args?["centerSymbolCanvasOffset"] as? Double) ?? 8)
    interfaceStyle = brightness == "dark" ? .dark : .light
    channel = FlutterMethodChannel(
      name: "pet_care_harmony/ios_native_dock_\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    configureRootView()
    configureTabBarController()
    configureChannel()

    if let selectedTab = args?["selectedTab"] as? String {
      setSelectedTab(named: selectedTab)
    } else {
      setSelectedTab(named: IosNativeDockTab.checklist.channelName)
    }
  }

  func view() -> UIView {
    rootView
  }

  private func configureRootView() {
    rootView.backgroundColor = .clear
    let controllerView = tabBarController.view!
    controllerView.translatesAutoresizingMaskIntoConstraints = false
    controllerView.backgroundColor = .clear
    controllerView.clipsToBounds = false

    rootView.addSubview(controllerView)

    NSLayoutConstraint.activate([
      controllerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 10),
      controllerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -10),
      controllerView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 18),
      controllerView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -10),
    ])
  }

  private func configureTabBarController() {
    tabBarController.delegate = self
    tabBarController.viewControllers = makeViewControllers()
    tabBarController.selectedIndex = 0

    let tabBar = tabBarController.tabBar
    tabBar.isTranslucent = true
    tabBar.overrideUserInterfaceStyle = interfaceStyle
    tabBar.backgroundImage = nil
    tabBar.shadowImage = UIImage()

    let appearance = UITabBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundEffect = nil
    appearance.backgroundColor = UIColor.clear
    appearance.shadowColor = .clear
    configureItemAppearance(appearance.inlineLayoutAppearance)
    configureItemAppearance(appearance.stackedLayoutAppearance)
    configureItemAppearance(appearance.compactInlineLayoutAppearance)

    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
    tabBar.backgroundColor = .clear
  }

  private func makeViewControllers() -> [UIViewController] {
    controllersByTab.removeAll()

    let checklist = makeTabController(for: .checklist)
    let overview = makeTabController(for: .overview)
    let placeholder = makeAddPlaceholderController()
    let pets = makeTabController(for: .pets)
    let me = makeTabController(for: .me)

    addPlaceholderController = placeholder
    return [checklist, overview, placeholder, pets, me]
  }

  private func makeTabController(for tab: IosNativeDockTab) -> UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = .clear
    controller.tabBarItem = UITabBarItem(
      title: tab.title,
      image: UIImage(
        systemName: tab.iconName,
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
      ),
      tag: tab.rawValue
    )
    controllersByTab[tab] = controller
    return controller
  }

  private func makeAddPlaceholderController() -> UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = .clear
    let image = makeCenteredAddImage()
    let item = UITabBarItem(title: " ", image: image, tag: 999)
    item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100)
    controller.tabBarItem = item
    return controller
  }

  private func makeCenteredAddImage() -> UIImage? {
    let configuration = UIImage.SymbolConfiguration(pointSize: centerSymbolSize, weight: .semibold)
    guard let baseImage = UIImage(
      systemName: "plus.circle.fill",
      withConfiguration: configuration
    )?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal) else {
      return nil
    }

    let horizontalPadding: CGFloat = 12
    let verticalPadding: CGFloat = 12
    let canvasSize = CGSize(
      width: max(44, baseImage.size.width + horizontalPadding),
      height: max(
        44,
        baseImage.size.height + verticalPadding + abs(centerSymbolCanvasOffset) * 2
      )
    )
    let renderer = UIGraphicsImageRenderer(size: canvasSize)

    return renderer.image { _ in
      let origin = CGPoint(
        x: (canvasSize.width - baseImage.size.width) / 2,
        y: (canvasSize.height - baseImage.size.height) / 2 + centerSymbolCanvasOffset
      )
      baseImage.draw(in: CGRect(origin: origin, size: baseImage.size))
    }.withRenderingMode(.alwaysOriginal)
  }

  private func configureItemAppearance(_ itemAppearance: UITabBarItemAppearance) {
    itemAppearance.selected.iconColor = .systemOrange
    itemAppearance.selected.titleTextAttributes = [
      .foregroundColor: UIColor.systemOrange,
      .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
    ]
    itemAppearance.normal.iconColor = UIColor.secondaryLabel
    itemAppearance.normal.titleTextAttributes = [
      .foregroundColor: UIColor.secondaryLabel,
      .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
    ]
  }

  private func configureChannel() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "setSelectedTab":
        self.setSelectedTab(named: call.arguments as? String)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setSelectedTab(named tabName: String?) {
    guard
      let tabName,
      let selectedTab = IosNativeDockTab.allCases.first(where: { $0.channelName == tabName }),
      let controller = controllersByTab[selectedTab]
    else {
      return
    }

    isSyncingSelection = true
    tabBarController.selectedViewController = controller
    isSyncingSelection = false
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    shouldSelect viewController: UIViewController
  ) -> Bool {
    if viewController === addPlaceholderController {
      channel.invokeMethod("addTapped", arguments: nil)
      return false
    }
    return true
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    didSelect viewController: UIViewController
  ) {
    guard !isSyncingSelection else {
      return
    }
    guard let tab = controllersByTab.first(where: { $0.value === viewController })?.key else {
      return
    }
    channel.invokeMethod("tabSelected", arguments: tab.channelName)
  }
}
