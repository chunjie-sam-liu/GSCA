import { Component, OnInit } from '@angular/core';
import features from 'src/app/shared/constants/features';

@Component({
  selector: 'app-search-box',
  templateUrl: './search-box.component.html',
  styleUrls: ['./search-box.component.css'],
})
export class SearchBoxComponent implements OnInit {
  public features = features;
  constructor() {}

  ngOnInit(): void {}
}
