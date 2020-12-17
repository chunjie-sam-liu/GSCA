import { Component, OnInit } from '@angular/core';
import modules from 'src/app/shared/constants/modules';

@Component({
  selector: 'app-search-box',
  templateUrl: './search-box.component.html',
  styleUrls: ['./search-box.component.css'],
})
export class SearchBoxComponent implements OnInit {
  public modules = modules;
  constructor() {}

  ngOnInit(): void {}
}
