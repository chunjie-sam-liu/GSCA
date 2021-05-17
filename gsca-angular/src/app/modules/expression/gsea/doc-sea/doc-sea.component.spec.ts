import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSeaComponent } from './doc-sea.component';

describe('DocSeaComponent', () => {
  let component: DocSeaComponent;
  let fixture: ComponentFixture<DocSeaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSeaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSeaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
