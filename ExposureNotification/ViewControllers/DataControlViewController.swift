//
//  DataControlViewController.swift
//  ExposureNotification
//
//  Created by Shiva Huang on 2021/4/8.
//  Copyright © 2021 AI Labs. All rights reserved.
//

import SnapKit
import UIKit

class DataControlViewController: UIViewController {
    private let viewModel: DataControlViewModel
    
    private lazy var tableView: UITableView = {
        let view = UITableView()

        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UIColor.clear
        view.tableFooterView = UIView()
        view.alwaysBounceVertical = false
        view.register(TogglableTableViewCell.self, forCellReuseIdentifier: "TogglableTableViewCell")
        
        return view
    }()
    
    init(viewModel: DataControlViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Color.background
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        viewModel.$title { [weak self] (title) in
            self?.title = title
        }
        
        viewModel.$items { [weak self] (_) in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }

        viewModel.exposureNotificationEngageHandler = { [weak self] (reason, completion) in
            switch reason {
            case .disabled, .unauthorized:
                completion()

            case .bluetoothOff:
                let confirm = UIAlertController(title: Localizations.EnableBluetoothAlert.title, message: Localizations.EnableBluetoothAlert.message, preferredStyle: .alert)
                confirm.addAction(UIAlertAction(title: Localizations.Alert.Button.cancel, style: .cancel) { _ in
                    completion()
                })
                confirm.addAction(UIAlertAction(title: Localizations.EnableBluetoothAlert.Button.enable, style: .default) { _ in
                    AppCoordinator.shared.openSettingsApp()
                    completion()
                })
                self?.present(confirm, animated: true, completion: nil)

            case .denied:
                AppCoordinator.shared.openSettingsApp()
                completion()

            case .restricted:
                //TODO: Show message to unlock restriction
                completion()

            case .unsupported:
                //TODO: Show message to upgrade OS
                completion()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        
        super.viewWillDisappear(animated)
    }
}

extension DataControlViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemViewModel = viewModel.items[indexPath.row]
        
        switch itemViewModel {
        case is TracingCellViewModel:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TogglableTableViewCell", for: indexPath) as! TogglableTableViewCell
            
            cell.viewModel = itemViewModel as! TracingCellViewModel
            
            return cell
            
        default:
            fatalError("Unknown cell view model: \(itemViewModel)")
        }
    }
}

extension DataControlViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DataControlViewController {
    enum Color {
        static let background = UIColor.init(red: (235/255.0), green: (235/255.0), blue: (235/255.0), alpha: 1)
    }
}
