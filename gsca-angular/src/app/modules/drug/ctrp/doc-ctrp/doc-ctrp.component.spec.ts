import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocCtrpComponent } from './doc-ctrp.component';

describe('DocCtrpComponent', () => {
  let component: DocCtrpComponent;
  let fixture: ComponentFixture<DocCtrpComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocCtrpComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocCtrpComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
